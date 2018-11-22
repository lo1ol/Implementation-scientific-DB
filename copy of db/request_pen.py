from request_pen_const import *

"""
	request имеет следующий формат
	request := [[ req, req, ... ], [ req, req, ... ], ...] -- первый уровень -- уровень "или", второй уровень -- уровень "и"
	req := (field, <type>, val) | [req, 'or', req]
	<type> := 'fs' | 're' | <op>
	<op> := '>' | '<' | '>=' | '<=' | '=' | '!=' | is
	
	val -- любое из значений (строка, число, дата, None)
	
	сортирует вывод в указанном порядке
	orders := [(field, [DESC|ASC]), (field, [DESC|ASC]), ...]
"""

def make_request(view, request, order=[]):
	body = "SELECT * FROM ("
	for and_request in request:
		and_body = make_and_request(view, and_request, order)
		body += f"\n(\n{and_body}\n)\nUNION\n"
	body = body[:-7] + '\n) as req\n'
	if order:
		body += 'ORDER BY\n'
		for field, _ord in order:
			body += f"\t{field} {_ord} NULLS LAST,\n"
		body = body[0:-2] + '\n'
	print(body)
	return body


def make_and_request(view, request, order=[]): # ПРОВЕРИТЬ НА НАЛИЧИЕ ИНЪЕКЦИЙ
	body = "SELECT \n"

	aggr_fields = []
	for aggr_field in VIEW_ATTRIBUTES[view][1]:
		aggr_fields.extend(aggr_field.split()[1:])

	fields = VIEW_ATTRIBUTES[view][0].copy()
	for aggr_field in aggr_fields:
		fields.remove(aggr_field)

	for field in fields:
		body += f"\t{field},\n"

	for aggr_field in VIEW_ATTRIBUTES[view][1]:
		if len(aggr_field.split()) > 2:
			name = aggr_field.split()[0]
			aggr_field = f"{make_array_str(aggr_field.split()[1:])} "
		else:
			name = aggr_field.split()[0]
			aggr_field = aggr_field.split()[1]
		body += f"\tarray_agg(DISTINCT {aggr_field}) as {name},\n"
	body = body[:-2] + '\n'

	body += f'FROM\n\t{view}\n'
	if request:
		body += 'WHERE\n'
		for req in request:
			body += f"{parse_request(*req)}\n AND \n"
		body = body[:-7] + '\n'

	body += 'GROUP BY\n\t'
	line_len = 0
	for field in fields:
		if line_len + len(field) > 150:
			body += '\n\t'
			line_len = 0
		body += f"{field}, "
		line_len += len(field)
	body = body[:-2] + "\n"

	if order:
		body += 'ORDER BY\n'
		for field, _ord in order:
			body += f"\t{field} {_ord} NULLS LAST,\n"
		body = body[0:-2] + '\n'

	body = body[:-1]
	return body


def parse_request(field, op, val, ind=1): # ПРОВЕРИТЬ НА НАЛИЧИЕ ИНЪЕКЦИЙ
	if op == 'or':
		request = '\n' + \
		          '\t'*(ind) + '(' + '\n' + \
		          f"{parse_request(*field, ind + 1)}\n" + \
		          '\t'*ind + "OR\n" + \
		          f"{parse_request(*val, ind + 1)}\n" + \
		          '\t'*ind + ')'
	elif op == 'fs':
		request = '\t'*ind + f"(to_tsvector('russian', {field}) @@ plainto_tsquery('russian', $fulltextsearch${val}$fulltextsearch$) OR to_tsvector('english', {field}) @@ plainto_tsquery('english', $fulltextsearch${val}$fulltextsearch$))"
	elif op == 're':
		request = '\t'*ind + f"{field} ~* $regexp${val}$regexp$"
	elif op in ['>', '<', '>=', '<=', '=', '!=', 'is']:
		if val != None:
			request = '\t'*ind + f"{field} {op} $value${val}$value$"
		else:
			request = '\t'*ind + f"{field} is NULL"
	else:
		raise RuntimeError("Invalid request!")

	if ind == 1:
		form_request = ""
		for line in request.split('\n'):
			if line.strip():
				form_request += line + '\n'
		request = form_request[:-1]

	return request


def make_array_str(list):
	result = 'ARRAY [ '
	for elem in list:
		result += f"{elem}, "

	result = result[:-2] + ' ]'
	return result


if __name__ == "__main__":
	make_request("main_data.fast_show_view", [[('author', 're', 'иванов%'), (('publication_year', '>', '2008'), 'or', ('publication_year', '=', None))], [('abstract', 'fs', 'модель'), (('publication_year', '>', '2008'), 'or', ('publication_year', '=', None))]], [('publication_year', 'DESC')])