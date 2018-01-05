WeaverError = {}

# Error code indicating some error other than those enumerated here.
WeaverError.OTHER_CAUSE = -1


# Error code indicating that something has gone wrong with the server.
# If you get this error code, it is Weavers's fault. Contact us at
# https://weaverplatform.com/help
WeaverError.INTERNAL_SERVER_ERROR = 1


# Error code indicating the connection to the Weaver Server failed.
WeaverError.CONNECTION_FAILED = 100


# Error code indicating the specified Node doesn't exist.
WeaverError.NODE_NOT_FOUND = 101


# Error code indicating you tried to query with a datatype that doesn't
# support it, like exact matching an array or object.
WeaverError.INVALID_QUERY = 102


# Error code indicating an unspecified node id.
WeaverError.MISSING_NODE_ID = 104


# Error code indicating an invalid key name. Keys are case-sensitive. They
# must start with a letter, and a-zA-Z0-9_ are the only valid characters.
WeaverError.INVALID_KEY_NAME = 105


# Error code indicating a malformed pointer. You should not see this unless
# you have been mucking about changing internal Weaver code.
WeaverError.INVALID_POINTER = 106


# Error code indicating that badly formed JSON was received upstream. This
# either indicates you have done something unusual with modifying how
# things encode to JSON, or the network is failing badly.
WeaverError.INVALID_JSON = 107


# Error code indicating that the feature you tried to access is only
# available internally for testing purposes.
WeaverError.COMMAND_UNAVAILABLE = 108


# You must call Weaver.initialize before using the Weaver SDK.
WeaverError.NOT_INITIALIZED = 109


# Error code indicating that a field was set to an inconsistent type.
WeaverError.INCORRECT_TYPE = 111


# Error code indicating an invalid channel name. A channel name is either
# an empty string (the broadcast channel or contains only a-zA-Z0-9_
# characters and starts with a letter.
WeaverError.INVALID_CHANNEL_NAME = 112


# Error code indicating that push is misconfigured.
WeaverError.PUSH_MISCONFIGURED = 115


# Error code indicating that the object is too large.
WeaverError.OBJECT_TOO_LARGE = 116


# Error code indicating that the operation isn't allowed for clients.
WeaverError.OPERATION_FORBIDDEN = 119


# Error code indicating the result was not found in the cache.
WeaverError.CACHE_MISS = 120


# Error code indicating that an invalid key was used in a nested
# JSONObject.
WeaverError.INVALID_NESTED_KEY = 121


# Error code indicating that an invalid filename was used for WeaverFile.
# A valid file name contains only a-zA-Z0-9_. characters and is between 1
# and 128 characters.
WeaverError.INVALID_FILE_NAME = 122


# Error code indicating an invalid ACL was provided.
WeaverError.INVALID_ACL = 123


# Error code indicating that the request timed out on the server. Typically
# this indicates that the request is too expensive to run.
WeaverError.TIMEOUT = 124


# Error code indicating that the email address was invalid.
WeaverError.INVALID_EMAIL_ADDRESS = 125


# Error code indicating a missing content type.
WeaverError.MISSING_CONTENT_TYPE = 126


# Error code indicating a missing content length.
WeaverError.MISSING_CONTENT_LENGTH = 127


# Error code indicating an invalid content length.
WeaverError.INVALID_CONTENT_LENGTH = 128


# Error code indicating a file that was too large.
WeaverError.FILE_TOO_LARGE = 129


# Error code indicating an error saving a file.
WeaverError.FILE_SAVE_ERROR = 130


# Error code indicating that a unique field was given a value that is
WeaverError.DUPLICATE_VALUE = 137


# Error code indicating that a role's name is invalid.
WeaverError.INVALID_ROLE_NAME = 139


# Error code indicating that an application quota was exceeded.  Upgrade to resolve.
WeaverError.EXCEEDED_QUOTA = 140


# Error code indicating that a Cloud Code script failed.
WeaverError.SCRIPT_FAILED = 141


# Error code indicating that a Cloud Code validation failed.
WeaverError.VALIDATION_ERROR = 142


# Error code indicating that invalid image data was provided.
WeaverError.INVALID_IMAGE_DATA = 143


# Error code indicating an unsaved file.
WeaverError.UNSAVED_FILE_ERROR = 151


# Error code indicating an invalid push time.
WeaverError.INVALID_PUSH_TIME_ERROR = 152


# Error code indicating an error deleting a file.
WeaverError.FILE_DELETE_ERROR = 153


# Error code indicating that the application has exceeded its request
WeaverError.REQUEST_LIMIT_EXCEEDED = 155


# Error code indicating an invalid event name.
WeaverError.INVALID_EVENT_NAME = 160


# Error code indicating a that a Node with given ID can't be recreated again
WeaverError.NODE_ALREADY_EXISTS = 161


# Error code indicating that the username is missing or empty.
WeaverError.USERNAME_MISSING = 200


# Error code indicating that the password is missing or empty.
WeaverError.PASSWORD_MISSING = 201


# Error code indicating that the username has already been taken.
WeaverError.USERNAME_TAKEN = 202


# Error code indicating that the email has already been taken.
WeaverError.EMAIL_TAKEN = 203


# Error code indicating that the email is missing, but must be specified.
WeaverError.EMAIL_MISSING = 204


# Error code indicating that a user with the specified email was not found.
WeaverError.EMAIL_NOT_FOUND = 205


# Error code indicating that a user object without a valid session could
WeaverError.SESSION_MISSING = 206


# Error code indicating that a user can only be created through signup.
WeaverError.MUST_CREATE_USER_THROUGH_SIGNUP = 207


# Error code indicating that an an account being linked is already linked
# to another user.
WeaverError.ACCOUNT_ALREADY_LINKED = 208


# Error code indicating that the current session token is invalid.
WeaverError.INVALID_SESSION_TOKEN = 209


# Error code indicating that the username does not exist
WeaverError.USERNAME_NOT_FOUND = 210


# Password given is incorrect
WeaverError.PASSWORD_INCORRECT = 211


# Error code indicating that a user cannot be linked to an account because
# that account's id could not be found.
WeaverError.LINKED_ID_MISSING = 250


# Error code indicating that a user with a linked (e.g. Facebook account
# has an invalid session.
WeaverError.INVALID_LINKED_SESSION = 251


# Error code indicating that a service being linked (e.g. Facebook or
# Twitter is unsupported.
WeaverError.UNSUPPORTED_SERVICE = 252


# A value can not be parsed as the specified datatype
WeaverError.DATATYPE_INVALID = 322;


# A specified datatype (e.g. 'number') is not supported
WeaverError.DATATYPE_UNSUPPORTED = 333;


# A specified write operation (e.g. 'merge-nodes') is not supported
WeaverError.WRITE_OPERATION_NOT_EXISTS = 344;


# Some necessary fields in the write operation json is missing
WeaverError.WRITE_OPERATION_INVALID = 345;

# Failed executing batch, message given from connector, this should never occur though.
WeaverError.WRITE_OPERATION_FAILED = 366;

# Error code indicating that there were multiple errors. Aggregate errors
# have an "errors" property, which is an array of error objects with more
# detail about each error that occurred.
WeaverError.AGGREGATE_ERROR = 600


# Error code indicating the client was unable to read an input file.
WeaverError.FILE_READ_ERROR = 601


# Error code indicating a real error code is unavailable because
# we had to use an XDomainRequest object to allow CORS requests in
# Internet Explorer, which strips the body from HTTP responses that have
# a non-2XX status code.
WeaverError.X_DOMAIN_REQUEST = 602


# Error code indicating that the requested file does not exist.
WeaverError.FILE_NOT_EXISTS_ERROR = 603


# Error code indicating that no settable model property could be found which matches the supplied string.
WeaverError.MODEL_PROPERTY_NOT_FOUND = 604

# Error code reminding you that deep properties of a model cannot be statically set.
WeaverError.CANNOT_SET_DEEP_STATIC = 605

# Error code indicating that a model was not found.
WeaverError.MODEL_NOT_FOUND = 206

WeaverError.MODEL_VERSION_NOT_FOUND = 207

module.exports = WeaverError
