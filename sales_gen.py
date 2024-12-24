# 1str comment - Ctrl + /
# morestr comment - Shift + Alt + A

import pg8000
# Установление соединения с базой данных 
conn = pg8000.connect( 
    database="de_catman_proj", 
    user="postgres", 
    password="$uperu$er", 
    host="localhost", 
    port=5432 )

# Создание курсора 
cur = conn.cursor() 

# Выполнение SQL-запроса 
cur.execute("SELECT * FROM dw.geo_dim") 

# Получение результатов 
rows = cur.fetchall() 
for row in rows: print(row) 

# Закрытие курсора и соединения 
cur.close() 
conn.close()