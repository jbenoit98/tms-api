from flask import request, Blueprint, jsonify
import json
from api import utilities


departments_blueprint = Blueprint('departments_blueprint', __name__)

@departments_blueprint.route('/v1.0/create/department', methods = ['POST'])
def create_department():
    if not request.json or \
            not 'department' in request.json:
        return jsonify(status='error',data={},message='Missing required name/value pair(s)'),400

    try:
        conn = utilities.connect_db()
        ##Insert statements
        conn.close()
    except Exception as e:
        return jsonify(status='error',data={},message=e),400

@departments_blueprint.route('/v1.0/get/department/<int:department_pk>', methods = ['GET'])
def get_department(department_pk):
    try:
        j = {}
        j['order'] = request.args.get('order')
        j['limit'] = request.args.get('limit')
        j['offset'] = request.args.get('offset')
        j['include'] = request.args.get('include')
        conn = utilities.connect_db()
        ##get department by id
        conn.close()
    except Exception as e:
        return jsonify(status='error',data={},message=e),400

@departments_blueprint.route('/v1.0/get/departments', methods = ['GET'])
def get_departments():
    try:
        j = {}
        j['order'] = request.args.get('order')
        j['limit'] = request.args.get('limit')
        j['offset'] = request.args.get('offset')
        j['include'] = request.args.get('include') # which attributes to return
        conn = utilities.connect_db()
        ##Get all departments
        conn.close()
    except Exception as e:
        return jsonify(status='error',data={},message=e),400

@departments_blueprint.route('/v1.0/update/department/<int:department_pk>', methods = ['PATCH'])
def update_department(department_pk):
    if not request.json:
        return jsonify(status='error',data={},message='Missing required name/value pair(s)'),400

    try:
        request.json['customer_fk'] = utilities.get_customer(get_jwt())
        conn = utilities.connect_db()
        ##update
        conn.close()
    except Exception as e:
        return jsonify(status='error',data={},message=e),400

@departments_blueprint.route('/v1.0/delete/department/<int:department_pk>', methods = ['DELETE'])
def delete_department(department_pk):
    try:
        conn = utilities.connect_db()
        ##deleteI
        conn.close()
    except Exception as e:
        return jsonify(status='error',data={},message=e),400



