from flask import request, Blueprint, jsonify
import json
from api import utilities

object_statuses_blueprint = Blueprint('object_statuses_blueprint', __name__)

@object_statuses_blueprint.route('/v1.0/create/object_status', methods = ['POST'])
def create_object_status():
    if not request.json or \
            not 'object_status' in request.json:
        return jsonify(status='error',data={},message='Missing required name/value pair(s)'),400

    try:
        conn = utilities.connect_db()
        ##create status
        conn.close()
    except Exception as e:
        return jsonify(status='error',data={},message=e),400

@object_statuses_blueprint.route('/v1.0/get/object_status/<int:object_status_pk>', methods = ['GET'])
def get_object_status(object_status_pk):
    try:
        j = {}
        j['include'] = request.args.get('include')
        conn = utilities.connect_db()
        ##get status by id
        conn.close()
    except Exception as e:
        return jsonify(status='error',data={},message=e),400

@object_statuses_blueprint.route('/v1.0/get/object_statuses', methods = ['GET'])
def get_object_statuses():
    try:
        j = {}
        j['order'] = request.args.get('order')
        j['limit'] = request.args.get('limit')
        j['offset'] = request.args.get('offset')
        j['include'] = request.args.get('include')
        conn = utilities.connect_db()
        ##get status by id
        conn.close()
    except Exception as e:
        return jsonify(status='error',data={},message=e),400

@object_statuses_blueprint.route('/v1.0/update/object_status/<int:object_status_pk>', methods = ['PATCH'])
def update_object_status(object_status_pk):
    if not request.json:
        return jsonify(status='error',data={},message='Missing required name/value pair(s)'),400
    try:
        conn = utilities.connect_db()
        ##update status by id
        conn.close()
    except Exception as e:
        return jsonify(status='error',data={},message=e),400

@object_statuses_blueprint.route('/v1.0/delete/object_status/<int:object_status_pk>', methods = ['DELETE'])
def delete_object_status(object_status_pk):
    try:
        conn = utilities.connect_db()
        ##delete status by id
        conn.close()
    except Exception as e:
        return jsonify(status='error',data={},message=e),400