import postgresql as pgs
from request_pen import make_request
from os import getpid


def print_request(*request):
	sql_request = make_request(*request)
	print(sql_request)
	conn = pgs.open('pq://Server:@localhost:5432/viniti_db')
	cursor_id = "cursor_%d" % getpid()
	print("START TRANSACTION")
	with conn.xact():
		conn.execute(f"DECLARE {cursor_id} CURSOR FOR ({sql_request});")
		cur = conn.cursor_from_id(cursor_id)
		for row in cur:
			print(row)
	print("END TRANSACTION")


if __name__ == "__main__":
	print_request("main_data.fast_search_view",
	      [
		      [('abstract', 'fs', 'модель')]
	      ])
