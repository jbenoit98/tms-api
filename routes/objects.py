from flask import request, Blueprint, jsonify
import json
from tms_api.api import utilities

objects_blueprint = Blueprint('objects_blueprint', __name__)

@objects_blueprint.route('/v1.0/create/object', methods = ['POST'])
def create_object():
    if not request.json or \
            not 'object_number' in request.json:
        return jsonify(status='error',data={},message='Missing required name/value pair(s)'),400

    try:
        conn = utilities.connect_db()
        ##Insert statements
        conn.close()
    except Exception as e:
        return jsonify(status='error',data={},message=e),400

@objects_blueprint.route('/v1.0/get/object/<int:object_pk>', methods = ['GET'])
def get_object(object_pk):
    try:
        j = {}
        conn = utilities.connect_db()
        #select statement fo object_pk
        conn.close()
        #return data as json
    except Exception as e:
        return jsonify(status='error',data={},message=e),400

@objects_blueprint.route('/v1.0/get/objects', methods = ['GET'])
def get_objects():
    try:
        j = {}
        # pass payload params to use in ordering and pagination
        j['order'] = request.args.get('order')
        j['limit'] = request.args.get('limit')
        j['offset'] = request.args.get('offset')
        conn = utilities.connect_db()
        #select object data based using order value, limit and offset
        conn.close()
        #return data as json
    except Exception as e:
        return jsonify(status='error',data={},message=e),400

@objects_blueprint.route('/v1.0/update/object/<int:object_pk>', methods = ['PATCH'])
def update_object(object_pk):
    if not request.json:
        return jsonify(status='error',data={},message='Missing required name/value pair(s)'),400

    try:
        conn = utilities.connect_db()
        #Update using json payload
        conn.close()
        #return data as json
    except Exception as e:
        return jsonify(status='error',data={},message=e),400

@objects_blueprint.route('/v1.0/delete/object/<int:object_pk>', methods = ['DELETE'])
def delete_object(object_pk):
    try:
        j = {}
        conn = utilities.connect_db()
        #delete object
        conn.close()
        #return data as json
    except Exception as e:
        return jsonify(status='error',data={},message=e),400



