import unittest
import os
import shutil
import next_visit_occurrence
import add_past_history
import h5py
import numpy as np


class TestNextVisitAtScale(unittest.TestCase):

    def setUp(self):
        self.file_name = "../test/synpuf_inpatient_combined_test.hdf5"

        if os.path.exists(self.file_name):
            os.remove(self.file_name)

        shutil.copy("../test/synpuf_inpatient_5_combined.hdf5", self.file_name)

    def test_calculate_next_visit(self):

        next_visit_occurrence.main(self.file_name)


class TestAddPastHistoryAtScale(unittest.TestCase):

    def setUp(self):

        self.file_name = "../test/synpuf_inpatient_combined_test.hdf5"

        if os.path.exists(self.file_name):
            os.remove(self.file_name)

        shutil.copy("../test/synpuf_inpatient_5_combined.hdf5", self.file_name)

    def test_past_history(self):

        add_past_history.main(self.file_name, "/ohdsi/visit_occurrence/")


class TestAddNextVisitAndPastHistoryScale(unittest.TestCase):

    def setUp(self):
        self.file_name = "../test/synpuf_inpatient_combined_test.hdf5"

        if os.path.exists(self.file_name):
            os.remove(self.file_name)

        shutil.copy("../test/synpuf_inpatient_5_combined.hdf5", self.file_name)

    def test_past_history(self):
        next_visit_occurrence.main(self.file_name)
        add_past_history.main(self.file_name, "/computed/next/30_days/visit_occurrence/")
        add_past_history.main(self.file_name, "/ohdsi/visit_occurrence/")


def build_array_for_past_history(file_name):

    identifier_path = "/ohdsi/identifiers/person/"
    identifier_core_array_path = identifier_path + "core_array"
    identifier_column_annotations_path = identifier_path + "column_annotations"

    identifier_column_annotations_list = [["person_id"], [""], [""], ["integer"]]
    identifier_column_annotations = np.array(identifier_column_annotations_list)

    identifier_list = [[1], [1], [5], [5], [5], [5], [6], [9], [9], [9], [10]]

    identifier_core_array = np.array(identifier_list)

    visit_occurrence_path = "/ohdsi/visit_occurrence/"
    visit_occurrence_core_array_path = visit_occurrence_path + "core_array"
    visit_occurrence_column_annotations_path = visit_occurrence_path + "column_annotations"

    r1v = ["visit_concept_id", "visit_type_concept_id", "visit_start_julian_day", "visit_end_julian_day"]
    r2v = ["9201", "44818517", "", ""]
    r3v = ["Inpatient Visit", "Visit derived", "", ""]
    r4v = ["categorical", "categorical", "integer", "integer"]

    visit_annotations_list = [r1v, r2v, r3v, r4v]

    base_julian_day = 2455268

    # Visit annotations
    # 1 [person_id] -- 0 [list index position]
    visit = [
        [1, 1, base_julian_day + 10, base_julian_day + 20],  # 1 -- 0
        [1, 1, base_julian_day + 20 + 40, base_julian_day + 20 + 40 + 5],  # 1 -- 1
        [1, 1, base_julian_day, base_julian_day + 1],  # 5 -- 2
        [1, 1, base_julian_day + 2, base_julian_day + 10],  # 5 -- 3
        [1, 1, base_julian_day + 20, base_julian_day + 22],  # 5 -- 4
        [1, 1, base_julian_day + 22 + 30, base_julian_day + 22 + 30 + 2],  # 5 -- 5
        [1, 1, base_julian_day, base_julian_day + 2],  # 6 -- 6
        [1, 1, base_julian_day + 1, base_julian_day + 3],  # 9 -- 7
        [1, 1, base_julian_day + 3 + 2, base_julian_day + 3 + 2 + 40],  # 9 -- 8
        [1, 1, base_julian_day + 3 + 2 + 40 + 181, base_julian_day + 3 + 2 + 40 + 181 + 2],  # 9 -- 9
        [1, 1, base_julian_day - 1, base_julian_day],  # 10 -- 10
    ]

    visit_core_array = np.array(visit)

    visit_column_annotations = np.array(visit_annotations_list)

    with h5py.File(file_name, "w") as f5w:

        ida = f5w.create_dataset(identifier_column_annotations_path, shape=identifier_column_annotations.shape,
                                 dtype=identifier_column_annotations.dtype)
        ida[...] = identifier_column_annotations[...]

        idc = f5w.create_dataset(identifier_core_array_path, shape=identifier_core_array.shape,
                                 dtype=identifier_core_array.dtype)

        idc[...] = identifier_core_array

        va = f5w.create_dataset(visit_occurrence_column_annotations_path, shape=visit_column_annotations.shape,
                                dtype=visit_column_annotations.dtype)

        va[...] = visit_column_annotations
        #
        # print(visit_core_array.dtype)
        # print(visit_occurrence_core_array_path)
        vc = f5w.create_dataset(visit_occurrence_core_array_path, shape=visit_core_array.shape,
                                dtype=visit_core_array.dtype)

        vc[...] = visit_core_array[...]


class TestNextVisit(unittest.TestCase):

    def setUp(self):

        self.filename = "../test/ohdsi_sample.hdf5"

        if os.path.exists(self.filename):
            os.remove(self.filename)

        build_array_for_past_history(self.filename)

    def test_calculate_next_visit(self):
        next_visit_occurrence.main(self.filename)

        with h5py.File(self.filename) as f5:

            ids = f5["/ohdsi/identifiers/person/core_array"][...]

            """
            /computed/next/30_days/visit_occurrence
            /computed/days/visit_occurrence
            /computed/days/has/visit_occurrence
            /computed/position/visit_occurrence
            """

            #print(ids)


class TestAddPastHistory(unittest.TestCase):

    def setUp(self):

        self.filename = "../test/ohdsi_sample.hdf5"

        if os.path.exists(self.filename):
            os.remove(self.filename)

        build_array_for_past_history(self.filename)

    def test_add_past_history(self):

        add_past_history.main(self.filename, "/ohdsi/visit_occurrence/")

        "/computed/past_history/180/ohdsi/visit_occurrence/"

        with h5py.File(self.filename) as f5:
            pass

if __name__ == '__main__':
    unittest.main()
