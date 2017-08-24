import unittest
import os
import shutil
import next_visit_occurrence
import add_past_history


class TestNextVisit(unittest.TestCase):

    def setUp(self):
        self.file_name = "../test/synpuf_inpatient_combined_test.hdf5"

        if os.path.exists(self.file_name):
            os.remove(self.file_name)

        shutil.copy("../test/synpuf_ohdsi_combined.hdf5", self.file_name)

    def test_calculate_next_visit(self):

        next_visit_occurrence.main(self.file_name)


class TestAddPastHistory(unittest.TestCase):

    def setUp(self):

        self.file_name = "../test/synpuf_inpatient_combined_test.hdf5"

        if os.path.exists(self.file_name):
            os.remove(self.file_name)

        shutil.copy("../test/synpuf_ohdsi_combined.hdf5", self.file_name)

    def test_past_history(self):

        add_past_history.main(self.file_name, "/ohdsi/condition_occurrence/")


if __name__ == '__main__':
    unittest.main()
