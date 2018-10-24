import sqlalchemy as sa
import sqlparse
import argparse


def main(sql_file_name, connection_string, schema=None):

    engine = sa.create_engine(connection_string)
    with engine.connect() as connection:

        with open(sql_file_name) as f:

            sql_txt = f.read()
            sql_statements = sqlparse.split(sql_txt)

            if schema is not None:
                pre_statement = "set search_path=%s;" % schema
            else:
                pre_statement = ""

            for sql_statement in sql_statements:

                print(sql_statement)
                trans = connection.begin()
                try:
                    sql_to_execute = pre_statement + sql_statement
                    connection.execute(sql_to_execute)
                except:
                    trans.rollback()
                    raise
                trans.commit()

if __name__ == "__main__":
    arg_parser_obj = argparse.ArgumentParser()
    arg_parser_obj.add_argument("-f", dest="file_name", default="execute_sql_files.py")
    arg_parser_obj.add_argument("-c", dest="connection_string")
    arg_parser_obj.add_argument("-s", dest="schema", default=None)

    arg_obj = arg_parser_obj.parse_args()
    main(sql_file_name=arg_obj.file_name, connection_string=arg_obj.connection_string, schema=arg_obj.schema)

