import 'package:dart_frog_swagger/dart_frog_swagger.dart';

const initDataRequestBody = ApiRequestBody(
  description: 'Raw Telegram Mini App initData query string.',
  required: true,
  schema: {
    'type': 'object',
    'properties': {
      'initData': {
        'type': 'string',
        'description': 'Raw WebApp.initData string.',
      },
    },
    'required': ['initData'],
  },
  example: {
    'initData': 'user=%7B%22id%22%3A1%7D&auth_date=1710000000&hash=abc',
  },
);

const authInitDataResponses = <ApiResponse>[
  ApiResponse(
    statusCode: 200,
    description: 'Access JWT issued.',
    schema: {
      'type': 'object',
      'properties': {
        'accessToken': {'type': 'string'},
        'tokenType': {'type': 'string', 'example': 'Bearer'},
        'expiresIn': {'type': 'integer', 'example': 3600},
        'user': {
          'type': 'object',
          'properties': {
            'id': {'type': 'integer'},
            'firstName': {'type': 'string'},
            'lastName': {'type': 'string'},
            'username': {'type': 'string'},
            'avatarUrl': {'type': 'string'},
          },
        },
      },
      'required': ['accessToken', 'tokenType', 'expiresIn', 'user'],
    },
  ),
  ApiResponse(
    statusCode: 400,
    description: 'initData is missing or empty.',
    schema: {
      'type': 'object',
      'properties': {
        'error': {
          'type': 'string',
          'example': 'initData is required',
        },
      },
    },
  ),
  ApiResponse(
    statusCode: 401,
    description: 'Invalid or expired initData.',
    schema: {
      'type': 'object',
      'properties': {
        'error': {
          'type': 'string',
          'example': 'Invalid initData',
        },
      },
    },
  ),
  ApiResponse(
    statusCode: 405,
    description: 'Method not allowed.',
  ),
];
