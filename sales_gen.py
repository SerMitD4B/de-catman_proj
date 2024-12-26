# 1str comment - Ctrl + /
# morestr comment - Shift + Alt + A

#import pg8000
import pg8000.native
# Установление соединения с базой данных 
conn = pg8000.native.Connection( 
    user="postgres", 
    password="$uperu$er", 
    database="de_catman_proj", 
    host="localhost", 
    port=5432 )

for row in conn.run("SELECT * FROM dw.calendar_dim where year = 2016"):
    print(row)

conn.close

""" # Создание курсора 
cur = conn.cursor() 

# Выполнение SQL-запроса 
cur.execute("SELECT * FROM dw.calendar where year = 2015") 

# Получение результатов 
rows = cur.fetchall() 
for row in rows: print(row) 

# Закрытие курсора и соединения 
cur.close() 
conn.close() """