#!/usr/bin/env python
import argparse, sqlite3, time
from lxml import etree

dataTypeMap = {'id': 'TEXT',
               'type': 'TEXT',
               'x': 'FLOAT',
               'y': 'FLOAT',
               'z': 'FLOAT',
               'pos': 'FLOAT',
               'angle': 'FLOAT',
               'speed': 'FLOAT',
               'lane': 'TEXT',
               'slope': 'FLOAT',
               'edge': 'INTEGER'}

# Read SuMO XML file and retrieve data
def parseXML_setDB(XMLFile):
    DBData = []
    for _, node in etree.iterparse(XMLFile, tag='timestep'):
        tBar = node.get('time')
        # print("    Parsing XML file and retrieving data... time step", tBar,
              # end="\r")
        for child in node:
            attr = dict(child.items()) # object attributes
            attr['t'] = tBar # add time step to attributes
            DBData.append(attr) # add data entries
            if child.tag == 'person': # person objects have no type
                attr['type'] = 'person'
        node.clear(keep_tail=True)
    return DBData

# Create DB tables from DB structure
def create_table(tableName, attrDef):
    header = "CREATE TABLE " + tableName + " (\n"
    columnDef = ["    t FLOAT"]
    for attrName, attrType in attrDef.items():
        columnDef.append("    " + attrName + " " + attrType)
    columnDef.append("    PRIMARY KEY (t, id)")
    footer = '\n);'
    return header + ',\n'.join(columnDef) + footer

def insert_tuples(tableName, DBData, DB, SQLite):
    # l = len(DBData)
    for i, row in enumerate(DBData):
        # print("    Populating table with data... tuple", i+1, "of", l, end="\r")
        if len(row.keys()) > 0:
            columns = "'" + "', '".join(row.keys()) + "'"
            values = "'" + "', '".join(row.values()) + "'"
            attr = "(" + columns + ") VALUES (" + values + ")"
            DB.execute("INSERT INTO '" + tableName + "' " + attr + ";")
            SQLite.commit()

def run(inputFile, outputFile):
    tI = time.time() # debug
    # print("    Parsing XML file and retrieving data...", end="\r")
    DBData = parseXML_setDB(inputFile) # parse XML file and get DB data
    # print("    Parsing XML file and retrieving data... done                ")
    # SQLite management
    SQLite = sqlite3.connect(outputFile)
    DB = SQLite.cursor()
    fileTableName = inputFile.split('\\')[-1].split('.')[0].replace('-', '__')
    # Create DB table with data definition
    DB.execute(create_table(fileTableName, dataTypeMap))
    # print("    Table", fileTableName, "created")
    # print("    Populating table with data...", end="\r")
    insert_tuples(fileTableName, DBData, DB, SQLite) # populate table
    # print("    Populating table with data... done                       ")
    DB.close()
    # print("    Database successfully created")
    tF = time.time() # debug
    print("    Elapsed time:", tF-tI, "s") # debug


def main():
    # Command line interpreter
    parser = argparse.ArgumentParser(
        description="Converts all XML data files in a given folder to SQLite "
            "database")
    parser.add_argument("inputFileName", help="name of the XML input file")
    parser.add_argument("-f", "--file", default="SQLiteFromXML.db3",
                        help="name of the SQLite output file "
                            "(default name: SQLiteFromXML.db3)",
                        metavar="outputFileName", dest="outputFileName")
    args = vars(parser.parse_args())
    # Read arguments and create file name variables
    inFile = args['inputFileName']
    outFile = args['outputFileName']
    # Call main routine
    run(inFile, outFile)

if __name__ == "__main__": main()
