import os
import glob
import csv
from xlsxwriter.workbook import Workbook

OUTPUT_DIR = "output"

if __name__ == "__main__":
	if not os.path.exists(OUTPUT_DIR):
		os.mkdir(OUTPUT_DIR)
	for csvfile in glob.glob(os.path.join('.', '*.csv')):
	    workbook = Workbook(os.path.join(OUTPUT_DIR, csvfile[:-4] + '.xlsx'))
	    worksheet = workbook.add_worksheet()
	    with open(csvfile, 'rt', encoding='utf8') as f:
	        reader = csv.reader(f)
	        for r, row in enumerate(reader):
	            for c, col in enumerate(row):
	                worksheet.write(r, c, col)
	    workbook.close()
