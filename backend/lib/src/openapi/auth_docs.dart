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

const authSessionSchema = <String, Object?>{
  'type': 'object',
  'properties': {
    'accessToken': {'type': 'string'},
    'tokenType': {'type': 'string', 'example': 'Bearer'},
    'expiresIn': {'type': 'integer', 'example': 900},
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
};

const authInitDataResponses = <ApiResponse>[
  ApiResponse(
    statusCode: 200,
    description:
        'Access JWT issued. Refresh token is set as an HttpOnly cookie, '
        'not in the JSON body.',
    schema: authSessionSchema,
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

const authRefreshResponses = <ApiResponse>[
  ApiResponse(
    statusCode: 200,
    description:
        'New access JWT. The refresh cookie is rotated (new Set-Cookie).',
    schema: authSessionSchema,
  ),
  ApiResponse(
    statusCode: 401,
    description: 'Missing, expired, or reused refresh cookie.',
    schema: {
      'type': 'object',
      'properties': {
        'error': {
          'type': 'string',
          'example': 'Invalid refresh token',
        },
      },
    },
  ),
  ApiResponse(
    statusCode: 405,
    description: 'Method not allowed.',
  ),
];

const authLogoutResponses = <ApiResponse>[
  ApiResponse(
    statusCode: 204,
    description: 'Refresh token revoked (if present) and cookie cleared.',
  ),
  ApiResponse(
    statusCode: 405,
    description: 'Method not allowed.',
  ),
];

const debugAuthResponses = <ApiResponse>[
  ApiResponse(
    statusCode: 200,
    description: 'Fixed local Bearer token. Not a signed JWT.',
    schema: {
      'type': 'object',
      'properties': {
        'accessToken': {'type': 'string', 'example': 'dev-admin'},
        'tokenType': {'type': 'string', 'example': 'Bearer'},
        'user': {
          'type': 'object',
          'properties': {
            'id': {'type': 'integer', 'example': 1},
            'firstName': {'type': 'string', 'example': 'Debug'},
            'lastName': {'type': 'string', 'example': 'Admin'},
            'username': {'type': 'string', 'example': 'debug_admin'},
          },
        },
      },
      'required': ['accessToken', 'tokenType', 'user'],
    },
  ),
  ApiResponse(
    statusCode: 404,
    description: 'DEBUG_AUTH is not enabled.',
    schema: {
      'type': 'object',
      'properties': {
        'error': {
          'type': 'string',
          'example': 'Debug auth is disabled',
        },
      },
    },
  ),
  ApiResponse(
    statusCode: 405,
    description: 'Method not allowed.',
  ),
];
