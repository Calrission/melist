import 'package:dart_frog_swagger/dart_frog_swagger.dart';

const errorSchema = <String, Object?>{
  'type': 'object',
  'properties': {
    'error': {'type': 'string'},
  },
  'required': ['error'],
};

const unauthorizedResponse = ApiResponse(
  statusCode: 401,
  description: 'Missing or invalid Bearer token.',
);

const forbiddenResponse = ApiResponse(
  statusCode: 403,
  description: 'Resource belongs to another user.',
  schema: errorSchema,
);

const notFoundResponse = ApiResponse(
  statusCode: 404,
  description: 'Resource not found.',
  schema: errorSchema,
);

const conflictResponse = ApiResponse(
  statusCode: 409,
  description: 'Wish is already in the wishlist.',
  schema: errorSchema,
);

const badRequestResponse = ApiResponse(
  statusCode: 400,
  description: 'Invalid request body.',
  schema: errorSchema,
);

const methodNotAllowedResponse = ApiResponse(
  statusCode: 405,
  description: 'Method not allowed.',
);

const notImplementedResponse = ApiResponse(
  statusCode: 501,
  description: 'Endpoint is not implemented yet.',
  schema: errorSchema,
  example: {'error': 'Not implemented'},
);

const noContentResponse = ApiResponse(
  statusCode: 204,
  description: 'Done, no body.',
);

/// Responses shared by every protected stub route.
const protectedStubResponses = <ApiResponse>[
  unauthorizedResponse,
  methodNotAllowedResponse,
  notImplementedResponse,
];

const orderRequestBody = ApiRequestBody(
  description: 'Full list of ids in the new display order.',
  required: true,
  schema: {
    'type': 'object',
    'properties': {
      'order': {
        'type': 'array',
        'items': {'type': 'integer'},
      },
    },
    'required': ['order'],
  },
  example: {
    'order': [3, 1, 2],
  },
);

const idsRequestBody = ApiRequestBody(
  description: 'Ids to operate on.',
  required: true,
  schema: {
    'type': 'object',
    'properties': {
      'ids': {
        'type': 'array',
        'items': {'type': 'integer'},
      },
    },
    'required': ['ids'],
  },
  example: {
    'ids': [1, 2],
  },
);

const userSchema = <String, Object?>{
  'type': 'object',
  'properties': {
    'id': {'type': 'integer'},
    'firstName': {'type': 'string'},
    'lastName': {'type': 'string'},
    'username': {'type': 'string'},
    'nickname': {'type': 'string'},
    'avatarUrl': {'type': 'string'},
    'birthday': {'type': 'string', 'format': 'date'},
    'theme': {
      'type': 'string',
      'enum': ['system', 'light', 'dark'],
    },
  },
};

const wishSchema = <String, Object?>{
  'type': 'object',
  'properties': {
    'id': {'type': 'integer'},
    'ownerId': {'type': 'integer'},
    'name': {'type': 'string'},
    'price': {'type': 'number'},
    'url': {'type': 'string'},
    'description': {'type': 'string'},
    'coverUrl': {'type': 'string'},
    'status': {
      'type': 'string',
      'enum': ['draft', 'free', 'reserved'],
    },
  },
};

const wishInputSchema = <String, Object?>{
  'type': 'object',
  'properties': {
    'name': {'type': 'string'},
    'price': {'type': 'number'},
    'url': {'type': 'string'},
    'description': {'type': 'string'},
    'coverUrl': {'type': 'string'},
    'status': {
      'type': 'string',
      'enum': ['draft', 'free', 'reserved'],
    },
  },
  'required': ['name'],
};

const wishlistSchema = <String, Object?>{
  'type': 'object',
  'properties': {
    'id': {'type': 'integer'},
    'ownerId': {'type': 'integer'},
    'name': {'type': 'string'},
    'description': {'type': 'string'},
    'visibility': {
      'type': 'string',
      'enum': ['public', 'draft', 'link'],
    },
    'position': {'type': 'integer'},
    'shareToken': {'type': 'string'},
    'ownerNickname': {'type': 'string'},
    'items': {
      'type': 'array',
      'items': wishSchema,
    },
  },
};

const wishlistInputSchema = <String, Object?>{
  'type': 'object',
  'properties': {
    'name': {'type': 'string'},
    'description': {'type': 'string'},
    'visibility': {
      'type': 'string',
      'enum': ['public', 'draft', 'link'],
    },
    'wishIds': {
      'type': 'array',
      'items': {'type': 'integer'},
    },
  },
  'required': ['name'],
};
