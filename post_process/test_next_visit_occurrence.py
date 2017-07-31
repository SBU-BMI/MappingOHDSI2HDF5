import unittest
import os
import shutil
from next_visit_occurrence import main


class TestNextVisit(unittest.TestCase):

    def setUp(self):
        self.file_name = "../test/synpuf_inpatient_combined_test.hdf5"

        if os.path.exists(self.file_name):
            os.remove(self.file_name)

        shutil.copy("../test/synpuf_ohdsi_combined.hdf5", self.file_name)

    def test_calcualte_next_visit(self):

        main(self.file_name)
        raise


if __name__ == '__main__':
    unittest.main()
