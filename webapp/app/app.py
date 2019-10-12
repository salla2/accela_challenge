from typing import List, Dict
from flask import Flask
import mysql.connector
import json

app = Flask(__name__)


def active_user() -> List[Dict]:
    config = {
        'user': 'root',
        'password': 'accela',
        'host': 'db',
        'port': '3306',
        'database': 'users'
    }
    connection = mysql.connector.connect(**config)
    cursor = connection.cursor()
    cursor.execute('SELECT * FROM active_users')
    results = [{name: user_id} for (name, user_id) in cursor]

    cursor.close()
    connection.close()

    return results


@app.route('/')
def index() -> str:
    return json.dumps({'Hello World app active_users with their user_id': active_user()})


if __name__ == '__main__':
    app.run(host='0.0.0.0')

