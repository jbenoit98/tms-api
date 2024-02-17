from flask import Flask, jsonify,make_response
from flask_cors import CORS
from flask_restful import Api
import config as cfg
import os
from tornado.wsgi import WSGIContainer
from tornado.httpserver import HTTPServer
from tornado.ioloop import IOLoop
from datetime import timedelta
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from jsonschema import ValidationError

basedir = os.path.abspath(os.path.dirname(__file__))
app = Flask(__name__,)
api = Api(app, catch_all_404s=True)
cors = CORS(app, resources={r"/*": {"origins": "*"}})
app.config['JSONIFY_PRETTYPRINT_REGULAR'] = True

jwt = JWTManager(app)

limiter = Limiter(
    app,
    key_func=get_remote_address,
    default_limits=["1000 per day", "100 per hour"]
)

@app.errorhandler(400)
def bad_request(error):
    if isinstance(error.description, ValidationError):
        original_error = error.description
        return make_response(jsonify(status='error',
                                     data=None,
                                     error=original_error.message
                                    ), 400)
    # handle other "Bad Request"-errors
    return error

@app.errorhandler(429)
def ratelimit_handler(e):
    return jsonify(status='error',
                   data=None,
                   message=e.description
                   ), 429

@app.errorhandler(405)
def method_not_allowed_handler(e):
    return jsonify(status='error',
                   data=None,
                   message=e.description
                   ), 405

@jwt.expired_token_loader
def expired_token_callback(jwt_header, jwt_payload):
    return jsonify({
        'status': 'error',
        'data': {},
        'message': 'The token has expired'
    }), 401

@jwt.unauthorized_loader
def unauthorized_callback(jwt_header):
    return jsonify({
        'status': 'error',
        'data': {},
        'message': 'Missing Authorization Header'
    }), 401

@jwt.invalid_token_loader
def invalid_token_callback(jwt_header):
    return jsonify({
        'status': 'error',
        'data': {},
        'message': 'Signature verification failed'
    }), 422

#import api blueprints
from routes.auth import auth_blueprint
from routes.departments import departments_blueprint
from routes.objects import objects_blueprint
from routes.object_statuses import object_statuses_blueprint

#register endpoints
app.register_blueprint(auth_blueprint)
app.register_blueprint(departments_blueprint)
app.register_blueprint(objects_blueprint)
limiter.limit("100 per day",error_message='Too Many Requests to one or more Storage endpoints')(storage_blueprint)
app.register_blueprint(object_statuses_blueprint)

if __name__ == '__main__':
    http_server = HTTPServer(WSGIContainer(app), ssl_options={
        "certfile": cfg.cert['full'],
        "keyfile":  cfg.cert['priv'],
    })
    http_server.listen(443)
    IOLoop.instance().start()