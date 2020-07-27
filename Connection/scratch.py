from __future__ import print_function
import psycopg2

user = raw_input("Username:")
password = raw_input("Password:")
db = raw_input("Database:")
connection = psycopg2.connect(host='psql.wmi.amu.edu.pl',user=user,password=password,database=db)
cursor = connection.cursor()
query = raw_input("Query:")
cursor.execute(query)

for i in cursor.description:
    print(i[0]+ "  ",end= '')
print("")
base=cursor.fetchone()
rowCount = len(base)  # type: int
while base:
    for i in range(0,rowCount):
        if i == rowCount - 1:
            print(str(base[i]))
        else:
            print(str(base[i]),end = '')
    base=cursor.fetchone()

