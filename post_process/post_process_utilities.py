
def index_annotations(column_annotations, field_name):

    column_list = column_annotations[0,:].tolist()

    if field_name in column_list:
        start_position = column_list.index(field_name)
        reverse_column_list = list(column_list)
        reverse_column_list.reverse()
        end_position = len(column_list) - reverse_column_list.index(field_name)

        return (start_position, end_position)
    else:
        return None


def generate_person_dict(person_ids):
    last_person_id = int(person_ids[0, 0])

    starting_new_position = 0
    person_dict = {}
    for i in range(person_ids.shape[0]):
        person_id = int(person_ids[i, 0])

        if person_id != last_person_id:
            person_dict[last_person_id] = (starting_new_position, i - 1)
            starting_new_position = i
            last_person_id = person_id

    person_dict[person_id] = (starting_new_position + 1, i)

    return person_dict


def visit_start_slice(visit_annotations):

    visit_start = "visit_start_julian_day"
    visit_end = "visit_end_julian_day"

    slice_visit_start = index_annotations(visit_annotations, visit_start)
    slice_visit_end = index_annotations(visit_annotations, visit_end)

    return slice_visit_start, slice_visit_end