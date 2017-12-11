import argparse
import numpy as np
import h5py
import shutil
from post_process_utilities import generate_person_dict, visit_start_slice, index_annotations


def calculate_past_history(f5p, path_to_matrix, days_to_look_back,
                           base_path_identifier="/ohdsi/identifiers/person/", path_to_visit="/ohdsi/visit_occurrence/",
                           person_id="person_id", chunk_size=100
                           ):

    visit_annotations_path = path_to_visit + "column_annotations"
    visit_annotations = f5p[visit_annotations_path][...]

    identifiers_annotations_path = base_path_identifier + "column_annotations"
    identifier_annotations = f5p[identifiers_annotations_path][...]

    slice_person_id = index_annotations(identifier_annotations, person_id)
    person_ids = f5p[base_path_identifier + "core_array"][:, slice_person_id[0]:slice_person_id[1]]

    slice_visit_start, slice_visit_end = visit_start_slice(visit_annotations)
    visit_start = f5p[path_to_visit + "core_array"][:, slice_visit_start[0]:slice_visit_start[1]]
    visit_end = f5p[path_to_visit + "core_array"][:, slice_visit_end[0]:slice_visit_end[1]]

    person_dict = generate_person_dict(person_ids)

    # print(person_dict)

    core_array_to_process = f5p[path_to_matrix + "core_array"]
    core_array_annotations = f5p[path_to_matrix + "column_annotations"][...]

    number_of_rows, number_of_columns = core_array_to_process.shape

    row_indices_to_slice = []

    number_of_full_chunks = number_of_rows // chunk_size

    # print("number_of_full_chunks", number_of_full_chunks)

    # Create initial partitions
    start_i = 0
    for i in range(number_of_full_chunks):
        row_indices_to_slice += [[start_i, start_i + chunk_size - 1]]
        start_i = start_i + chunk_size

    row_indices_to_slice += [[start_i, number_of_rows - 1]]

    # print(row_indices_to_slice)
    # print(core_array_to_process.shape)

    # Correct starting and endpoints with regard to insure a whole person block is processed

    for i in range(len(row_indices_to_slice)):
        start_slice, end_slice = row_indices_to_slice[i]

        if i < len(row_indices_to_slice) - 1:
            person_id = person_ids[end_slice][0]

            person_start_i, person_end_i = person_dict[person_id]
            row_indices_to_slice[i][1] = person_end_i
            row_indices_to_slice[i + 1][0] = person_end_i + 1

    if row_indices_to_slice[-1][0] > row_indices_to_slice[-1][1]:
        row_indices_to_slice = row_indices_to_slice[:-1]

    # print(row_indices_to_slice)

    new_base_path = "/computed/past_history/" + str(days_to_look_back) + path_to_matrix
    past_history_matrix = f5p.create_dataset(new_base_path + "core_array", shape=(number_of_rows, number_of_columns),
                                             dtype=core_array_to_process.dtype, compression="gzip")

    f5p[new_base_path + "column_annotations"] = core_array_annotations

    for slice in row_indices_to_slice:
        start_slice, end_slice = slice
        end_slice_plus_one = end_slice + 1
        i_person_ids = person_ids[start_slice:end_slice_plus_one]

        i_person_dict = generate_person_dict(i_person_ids)

        i_matrix_of_interest = core_array_to_process[start_slice:end_slice_plus_one, :]
        i_start_date = visit_start[start_slice:end_slice_plus_one]
        i_end_date = visit_end[start_slice:end_slice_plus_one]

        i_past_history_matrix = np.zeros(shape=(end_slice - start_slice + 1, past_history_matrix.shape[1]), dtype=past_history_matrix.dtype)

        for i in range(end_slice - start_slice + 1):

            i_person_id = i_person_ids[i][0]
            i_start_person_id, i_end_person_id = i_person_dict[i_person_id] # index needs to be localized

            # print(i, i_start_person_id, i_end_person_id)

            current_visit_start_date = i_start_date[i][0]

            # print("current_visit_start_date", current_visit_start_date)
            visit_to_look_back_date = current_visit_start_date - days_to_look_back

            # print("visit_to_look_back_date", visit_to_look_back_date)

            past_visit_end_dates = i_end_date[i_start_person_id: i]  # TODO check

            # print("past_visit_end_dates", past_visit_end_dates)

            eligible_visit_past_dates = past_visit_end_dates[past_visit_end_dates >= visit_to_look_back_date]

            # print("eligible_visit_past_dates", eligible_visit_past_dates)

            rows_to_look_back = eligible_visit_past_dates.shape[0]

            # print("rows_to_look_back", rows_to_look_back)

            if rows_to_look_back:

                # print("*******")
                # print("matrix_to_sum", i_matrix_of_interest[i - 1 - rows_to_look_back : i])

                i_past_history_row = np.sum(i_matrix_of_interest[i - rows_to_look_back : i], axis=0)

                # print("i_past_history_row", i_past_history_row)
                i_past_history_matrix[i, :] = i_past_history_row

        past_history_matrix[start_slice:end_slice_plus_one,:] = i_past_history_matrix


def main(hdf5_file_name, path_to_matrix, days_to_look_back=180, make_backup=False, prefetch_amount=1000, base_path_identifier="/ohdsi/identifiers/person/"):

    if make_backup:
        print("Making backup copy of file")
        shutil.copy(hdf5_file_name, hdf5_file_name + ".bak")

    f5a = h5py.File(hdf5_file_name, "r+")

    calculate_past_history(f5a, path_to_matrix, days_to_look_back=days_to_look_back, chunk_size=prefetch_amount)

    f5a.close()


if __name__ == "__main__":

    arg_parse_obj = argparse.ArgumentParser(description="Sum up past events for a given person")
    arg_parse_obj.add_argument("-f", "--filename", dest="hdf5_filename")
    arg_parse_obj.add_argument("-p", "--path-to-matrix", dest="path_to_matrix")
    arg_parse_obj.add_argument("-d", "--days-to-look-back", dest="days_to_look_back", default=180)

    arg_obj = arg_parse_obj.parse_args()

    main(arg_obj.hdf5_filename, arg_obj.path_to_matrix, int(arg_obj.days_to_look_back), make_backup=True)