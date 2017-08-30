import argparse
import numpy as np
import h5py
import shutil
from post_process_utilities import generate_person_dict, visit_start_slice, index_annotations


def main(hdf5_file_name, path_to_matrix, days_to_look_back=180, make_backup=False, prefetch_amount=10000):

    if make_backup:
        print("Making backup copy of file")
        shutil.copy(hdf5_file_name, hdf5_file_name + ".bak")

    f5 = h5py.File(hdf5_file_name, "r+")

    path_to_visit = "/ohdsi/visit_occurrence/"

    visit_concept_name = "visit_concept_name"

    visit_annotations_path = path_to_visit + "column_annotations"

    visit_annotations = f5[visit_annotations_path][...]

    path_to_identifiers = "/ohdsi/identifiers/"
    identifiers_annotations_path = path_to_identifiers + "column_annotations"

    identifier_annotations = f5[identifiers_annotations_path][...]
    slice_visit_start, slice_visit_end = visit_start_slice(visit_annotations)

    person_id = "person_id"

    slice_person_id = index_annotations(identifier_annotations, person_id)

    person_ids = f5[path_to_identifiers + "core_array"][:, slice_person_id[0]:slice_person_id[1]]
    visit_start = f5[path_to_visit + "core_array"][:, slice_visit_start[0]:slice_visit_start[1]]
    visit_end = f5[path_to_visit + "core_array"][:, slice_visit_end[0]:slice_visit_end[1]]

    person_dict = generate_person_dict(person_ids)
    core_array_to_process = f5[path_to_matrix + "core_array"]
    core_array_annotations = f5[path_to_matrix + "column_annotations"][...]

    number_of_rows, number_of_columns = core_array_to_process.shape

    new_base_path = "/computed/past_history/" + str(days_to_look_back) + path_to_matrix
    past_history_matrix = f5.create_dataset(new_base_path + "core_array", shape=(number_of_rows, number_of_columns),
                      dtype=core_array_to_process.dtype, compression="gzip")

    f5[new_base_path + "column_annotations"] = core_array_annotations

    prefetch = True
    prefetch_start = 0
    prefetch_end = prefetch_amount

    for i in range(0, number_of_rows):

        if i == prefetch_end:
            prefetch = True

        person_id = person_ids[i][0]
        person_start, person_end = person_dict[person_id]

        if i % 1000 == 0 and i > 0:
            print(i)

        if prefetch:

            if i > 0:
                past_history_matrix[prefetch_start:prefetch_end,: ] = prefetch_past_history_matrix
                prefetch_start = prefetch_end
                prefetch_end = prefetch_start + prefetch_amount

            if prefetch_end > number_of_rows:
                prefetch_end = number_of_rows
            else:
                prefetch_person_ids = person_ids[prefetch_start: prefetch_end]
                last_person = np.where(person_ids == prefetch_person_ids[-1])

                prefetch_end = last_person[0][0] - 1

            prefetched_core_array = core_array_to_process[prefetch_start:prefetch_end, :]

            prefetch_past_history_matrix = np.zeros(shape=(prefetch_end - prefetch_start, number_of_columns))
            prefetch = False

        i_prefetch = i - prefetch_start

        current_visit_start_date = visit_start[i]
        visit_to_look_back_date = current_visit_start_date - days_to_look_back

        if i > person_start:
            past_visit_start_dates = visit_start[person_start: i-1]
            eligible_visit_past_dates = past_visit_start_dates[past_visit_start_dates >= visit_to_look_back_date]
            rows_to_look_back = eligible_visit_past_dates.shape[0]

            if rows_to_look_back:
                past_history = np.sum(prefetched_core_array[i_prefetch-1-rows_to_look_back: i_prefetch-1, :], axis=0)
                prefetch_past_history_matrix[i_prefetch, :] = past_history


    past_history_matrix[prefetch_start:prefetch_end, :] = prefetch_past_history_matrix


if __name__ == "__main__":

    arg_parse_obj = argparse.ArgumentParser(description="Sum up past events for a given person")
    arg_parse_obj.add_argument("-f", "--filename", dest="hdf5_filename")
    arg_parse_obj.add_argument("-p", "--path-to-matrix", dest="path_to_matrix")
    arg_parse_obj.add_argument("-d", "--days-to-look-back", dest="days_to_look_back", default=180)

    arg_obj = arg_parse_obj.parse_args()

    main(arg_obj.hdf5_filename, arg_obj.path_to_matrix, arg_obj.days_to_look_back, make_backup=True)