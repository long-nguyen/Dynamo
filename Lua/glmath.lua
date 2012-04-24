local ffi = require("ffi")

local C = ffi.C
ffi.cdef[[
typedef float GLMFloat;
union _vec2_t {
	GLMFloat f[2];
	struct { GLMFloat x; GLMFloat y; };
	struct { GLMFloat w; GLMFloat h; };
	struct { GLMFloat u; GLMFloat v; };

};
typedef union _vec2_t vec2_t;
union _vec3_t {
	GLMFloat f[3];
	struct { GLMFloat x; GLMFloat y; GLMFloat z; };
	struct { GLMFloat r; GLMFloat g; GLMFloat b; };
	struct { vec2_t xy; GLMFloat andY; };
};
typedef union _vec3_t vec3_t;
union _vec4_t {
	GLMFloat f[4];
	struct { GLMFloat x; GLMFloat y; GLMFloat z; GLMFloat w; };
	struct { GLMFloat r; GLMFloat g; GLMFloat b; GLMFloat a; };
	struct { vec3_t xyz; GLMFloat andW; };
};
typedef union _vec4_t vec4_t;
typedef struct _mat3_t {
	GLMFloat m00, m01, m02;
	GLMFloat m10, m11, m12;
	GLMFloat m20, m21, m22;
} mat3_t;
union _mat4_t {
	GLMFloat f[16];
	struct {
		GLMFloat m00, m01, m02, m03;
		GLMFloat m10, m11, m12, m13;
		GLMFloat m20, m21, m22, m23;
		GLMFloat m30, m31, m32, m33;
	};
};
typedef union _mat4_t mat4_t;
union _quat_t {
	GLMFloat f[4];
	struct { GLMFloat x; GLMFloat y; GLMFloat z; GLMFloat w; };
	struct { vec3_t vec; GLMFloat scalar; };
};
typedef union _quat_t quat_t;

struct _matrix_stack_t {
	mat4_t *items;
	unsigned int capacity;
	unsigned int count;
};
typedef struct _matrix_stack_t matrix_stack_t;

vec2_t vec2_create(GLMFloat x, GLMFloat y);
vec2_t vec2_add(const vec2_t v1, const vec2_t v2);
vec2_t vec2_sub(const vec2_t v1, const vec2_t v2);
vec2_t vec2_mul(const vec2_t v1, const vec2_t v2);
vec2_t vec2_div(const vec2_t v1, const vec2_t v2);
GLMFloat vec2_dot(const vec2_t v1, const vec2_t v2);
GLMFloat vec2_magSquared(const vec2_t v);
GLMFloat vec2_mag(const vec2_t v);
vec2_t vec2_normalize(const vec2_t v);
GLMFloat vec2_dist(const vec2_t v1, const vec2_t v2);
vec2_t vec2_scalarMul(const vec2_t v, GLMFloat s);
vec2_t vec2_scalarDiv(const vec2_t v, GLMFloat s);
vec2_t vec2_scalarAdd(const vec2_t v, GLMFloat s);
vec2_t vec2_scalarSub(const vec2_t v, GLMFloat s);
vec2_t vec2_negate(const vec2_t v);
vec2_t vec2_floor(vec2_t v);

vec3_t vec3_create(GLMFloat x, GLMFloat y, GLMFloat z);
vec3_t vec3_add(const vec3_t v1, const vec3_t v2);
vec3_t vec3_sub(const vec3_t v1, const vec3_t v2);
vec3_t vec3_mul(const vec3_t v1, const vec3_t v2);
vec3_t vec3_div(const vec3_t v1, const vec3_t v2);
GLMFloat vec3_dot(const vec3_t v1, const vec3_t v2);
GLMFloat vec3_magSquared(const vec3_t v);
GLMFloat vec3_mag(const vec3_t v);
vec3_t vec3_normalize(const vec3_t v);
GLMFloat vec3_dist(const vec3_t v1, const vec3_t v2);
vec3_t vec3_scalarMul(const vec3_t v, GLMFloat s);
vec3_t vec3_scalarDiv(const vec3_t v, GLMFloat s);
vec3_t vec3_scalarAdd(const vec3_t v, GLMFloat s);
vec3_t vec3_scalarSub(const vec3_t v, GLMFloat s);
vec3_t vec3_cross(const vec3_t v1, const vec3_t v2);
vec3_t vec3_negate(const vec3_t v);
vec3_t vec3_floor(vec3_t v);

vec4_t vec4_create(GLMFloat x, GLMFloat y, GLMFloat z, GLMFloat w);
vec4_t vec4_add(const vec4_t v1, const vec4_t v2);
vec4_t vec4_sub(const vec4_t v1, const vec4_t v2);
vec4_t vec4_mul(const vec4_t v1, const vec4_t v2);
vec4_t vec4_div(const vec4_t v1, const vec4_t v2);
GLMFloat vec4_dot(const vec4_t v1, const vec4_t v2);
GLMFloat vec4_magSquared(const vec4_t v);
GLMFloat vec4_mag(const vec4_t v);
vec4_t vec4_normalize(const vec4_t v);
GLMFloat vec4_dist(const vec4_t v1, const vec4_t v2);
vec4_t vec4_scalarMul(const vec4_t v, GLMFloat s);
vec4_t vec4_scalarDiv(const vec4_t v, GLMFloat s);
vec4_t vec4_scalarAdd(const vec4_t v, GLMFloat s);
vec4_t vec4_scalarSub(const vec4_t v, GLMFloat s);
vec4_t vec4_cross(const vec4_t v1, const vec4_t v2);
vec4_t vec4_negate(const vec4_t v);
vec4_t vec4_floor(vec4_t v);

quat_t quat_createf(GLMFloat x, GLMFloat y, GLMFloat z, GLMFloat angle);
quat_t quat_createv(vec3_t axis, GLMFloat angle);
mat4_t quat_to_mat4(const quat_t q);
quat_t mat4_to_quat(const mat4_t m);
mat4_t quat_to_ortho(const quat_t q);
quat_t ortho_to_quat(const mat4_t m);
GLMFloat quat_magSquared(const quat_t q);
GLMFloat quat_mag(const quat_t q);
quat_t quat_computeW(quat_t q);
quat_t quat_normalize(quat_t q);
quat_t quat_multQuat(const quat_t qA, const quat_t qB);
vec4_t quat_rotatePoint(const quat_t q, const vec4_t v);
vec3_t quat_rotateVec3(const quat_t q, const vec3_t v);
quat_t quat_inverse(const quat_t q);
GLMFloat quat_dotProduct(const quat_t qA, const quat_t qB);
quat_t quat_slerp(const quat_t qA, const quat_t qB, GLMFloat t);

mat4_t mat4_mul(const mat4_t m1, const mat4_t m2);
vec3_t vec3_mul_mat4(const vec3_t v, const mat4_t m, bool isPoint);
vec4_t vec4_mul_mat4(const vec4_t v, const mat4_t m);
mat4_t mat4_inverse(const mat4_t m, bool *success_out);
mat4_t mat4_transpose(const mat4_t m);
mat3_t mat4_extract_mat3(const mat4_t m);
GLMFloat mat4_det(mat4_t m);

bool vec2_equals(const vec2_t v1, const vec2_t v2);
bool vec3_equals(const vec3_t v1, const vec3_t v2);
bool vec4_equals(const vec4_t v1, const vec4_t v2);
bool mat4_equals(const mat4_t m1, const mat4_t m2);
bool quat_equals(const quat_t q1, const quat_t q2);


void printVec2(vec2_t vec);
void printVec3(vec3_t vec);
void printVec4(vec4_t vec);
void printMat3(mat3_t mat);
void printMat4(mat4_t mat);
void printQuat(quat_t quat);

mat4_t mat4_create_translation(GLMFloat x, GLMFloat y, GLMFloat z);
mat4_t mat4_translate(mat4_t mat, GLMFloat x, GLMFloat y, GLMFloat z);
mat4_t mat4_create_rotation(GLMFloat angle, GLMFloat x, GLMFloat y, GLMFloat z);
mat4_t mat4_rotate(mat4_t mat, GLMFloat angle, GLMFloat x, GLMFloat y, GLMFloat z);
mat4_t mat4_create_scale(GLMFloat x, GLMFloat y, GLMFloat z);
mat4_t mat4_scale(mat4_t mat, GLMFloat x, GLMFloat y, GLMFloat z);

mat4_t mat4_perspective(GLMFloat fov_radians, GLMFloat aspect, GLMFloat zNear, GLMFloat zFar);
mat4_t mat4_frustum(GLMFloat left, GLMFloat right, GLMFloat bottom, GLMFloat top, GLMFloat near, GLMFloat far);
// Generates an orthogonal viewing matrix
mat4_t mat4_ortho(GLMFloat left, GLMFloat right, GLMFloat bottom, GLMFloat top, GLMFloat near, GLMFloat far);
// Generates a lookat camera viewing matrix
mat4_t mat4_lookat(GLMFloat eyeX, GLMFloat eyeY, GLMFloat eyeZ,
                   GLMFloat centerX, GLMFloat centerY, GLMFloat centerZ,
                   GLMFloat upX, GLMFloat upY, GLMFloat upZ);


// Matrix stack
void matrix_stack_push_item(matrix_stack_t *stack, mat4_t item);
// Pushes an identical copy of the currently topmost matrix onto the stack (or the identity matrix if no item currently exists)
void matrix_stack_push(matrix_stack_t *stack);
// Pops an item off the stack
void matrix_stack_pop(matrix_stack_t *stack);
// Returns the topmost item in the stack
mat4_t matrix_stack_get_mat4(matrix_stack_t *stack);
// Returns the 3x3 portion of the topmost item in the stack
mat3_t matrix_stack_get_mat3(matrix_stack_t *stack);

void matrix_stack_translate(matrix_stack_t *stack, GLMFloat x, GLMFloat y, GLMFloat z);
void matrix_stack_rotate(matrix_stack_t *stack, GLMFloat angle, GLMFloat x, GLMFloat y, GLMFloat z);
void matrix_stack_scale(matrix_stack_t *stack, GLMFloat x, GLMFloat y, GLMFloat z);

extern const vec2_t GLMVec2_zero;
extern const vec3_t GLMVec3_zero;
extern const vec4_t GLMVec4_zero;

extern const mat3_t GLMMat3_identity;
extern const mat3_t GLMMat3_zero;
extern const mat4_t GLMMat4_identity;
extern const mat4_t GLMMat4_zero;
]]

mat4_create_translation = C.mat4_create_translation
mat4_translate = C.mat4_translate
mat4_create_rotation = C.mat4_create_rotation
mat4_rotate = C.mat4_rotate
mat4_create_scale = C.mat4_create_scale
mat4_scale = C.mat4_scale

mat4_perspective = C.mat4_perspective
mat4_frustum = C.mat4_frustum
mat4_ortho = C.mat4_ortho
mat4_lookat = C.mat4_lookat

-- Create the metatables

vec2_t = ffi.metatype("vec2_t",
{
	__call = C.printVec2,
	__add = function(a,b)
		if type(b) == "number" then
			return C.vec2_scalarAdd(a,b)
		else
			return C.vec2_add(a,b)
		end
	end,
	__sub = function(a,b)
		if type(b) == "number" then
			return C.vec2_scalarSub(a,b)
		else
			return C.vec2_sub(a,b)
		end
	end,
	__mul = function(a,b)
		if type(b) == "number" then
			return C.vec2_scalarMul(a,b)
		else
			return C.vec2_mul(a,b)
		end
	end,
	__div = function(a,b)
		if type(b) == "number" then
			return C.vec2_scalarDiv(a,b)
		else
			return C.vec2_div(a,b)
		end
	end,
	__eq = C.vec2_equals,
	__len = function(a) return C.vec2_mag(a) end,
	__index = {
		dot = C.vec2_dot,
		magSquared = C.vec2_magSquared,
		mag = C.vec2_mag,
		dist = C.vec2_dist,
		negate = C.vec2_negate,
		floor = C.vec2_floor,
		normalize = C.vec2_normalize,
	}
})

vec3_t = ffi.metatype("vec3_t",
{
	__call = C.printVec3,
	__add = function(a,b)
		if type(b) == "number" then
			return C.vec3_scalarAdd(a,b)
		else
			return C.vec3_add(a,b)
		end
	end,
	__sub = function(a,b)
		if type(b) == "number" then
			return C.vec3_scalarSub(a,b)
		else
			return C.vec3_sub(a,b)
		end
	end,
	__mul = function(a,b)
		if type(b) == "number" then
			return C.vec3_scalarMul(a,b)
		else
			return C.vec3_mul(a,b)
		end
	end,
	__div = function(a,b)
		if type(b) == "number" then
			return C.vec3_scalarDiv(a,b)
		else
			return C.vec3_div(a,b)
		end
	end,
	__eq = C.vec3_equals,
	__len = function(a) return C.vec3_mag(a) end,
	__index = {
		dot = C.vec3_dot,
		magSquared = C.vec3_magSquared,
		mag = C.vec3_mag,
		dist = C.vec3_dist,
		cross = C.vec3_cross,
		negate = C.vec3_negate,
		floor = C.vec3_floor,
		normalize = C.vec3_normalize,
	}
})

vec4_t = ffi.metatype("vec4_t",
{
	__call = C.printVec4,
	__add = function(a,b)
		if type(b) == "number" then
			return C.vec4_scalarAdd(a,b)
		else
			return C.vec4_add(a,b)
		end
	end,
	__sub = function(a,b)
		if type(b) == "number" then
			return C.vec4_scalarSub(a,b)
		else
			return C.vec4_sub(a,b)
		end
	end,
	__mul = function(a,b)
		if type(b) == "number" then
			return C.vec4_scalarMul(a,b)
		else
			return C.vec4_mul(a,b)
		end
	end,
	__div = function(a,b)
		if type(b) == "number" then
			return C.vec4_scalarDiv(a,b)
		else
			return C.vec4_div(a,b)
		end
	end,
	__eq = C.vec4_equals,
	__len = function(a) return C.vec4_mag(a) end,
	__index = {
		dot = C.vec4_dot,
		magSquared = C.vec4_magSquared,
		mag = C.vec4_mag,
		dist = C.vec4_dist,
		cross = C.vec4_cross,
		negate = C.vec4_negate,
		floor = C.vec4_floor,
		normalize = C.vec4_normalize,
	}
})
quat_t = ffi.metatype("quat_t",
{
	__call = C.printQuat,
	__mul = C.quat_multQuat,
	__eq = C.quat_equals,
	__index = {
		magSquared = C.quat_magSquared,
		mag = C.quat_mag,
		toOrtho = C.quat_to_ortho,
		slerp = C.quat_slerp,
		inverse = C.quat_inverse,
		computeW = C.quat_computeW,
		normalize = C.quat_normalize,
		rotatePoint = C.quat_rotateVec3
	}
})
mat4_t = ffi.metatype("mat4_t",
{
	__call = C.printMat4,
	__mul = C.mat4_mul,
	__eq = C.mat4_equals,
	__index = {
		det = C.mat4_det,
		inverse = C.mat4_inverse,
		transpose = C.mat4_transpose
	}
})


-- Matrix stack
matrix_stack_t = ffi.metatype("matrix_stack_t",
{
	__index = {
		push = C.matrix_stack_push,
		pushItem = C.matrix_stack_push_item,
		pop = C.matrix_stack_pop,
		mat4 = C.matrix_stack_get_mat4,
		mat3 = C.matrix_stack_get_mat3,
		translate = C.matrix_stack_translate,
		rotate = C.matrix_stack_rotate,
		scale = C.matrix_stack_scale
	}
})



vec2 = C.vec2_create
vec3 = C.vec3_create
vec4 = C.vec4_create
rgba = vec4
quat = C.quat_createf

-- There's some weirdness with luajit ffi and vec2_create, the other create functions work fine though
-- I need to figure this out (Only an issue in the iOS simulator(i386). Not necessary on arm)
vec2 = function(x,y)
    return vec3(x,y,0).xy
end

function rgb(r,g,b,a)
	a = a or 1
	return rgba(r,g,b,a)
end

vec2_zero = C.GLMVec2_zero
vec3_zero = C.GLMVec3_zero
vec4_zero = C.GLMVec4_zero

mat3_identity = C.GLMMat3_identity
mat4_identity = C.GLMMat4_identity
mat3_zero = C.GLMMat3_zero
mat4_zero = C.GLMMat4_zero

PI=math.pi
