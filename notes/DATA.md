# HRTrack Database and Types

Data is stored in one big binary-binary key value database.

Every key starts with a one byte relation type tag:
```d
enum RelationType : ubyte {
	UserDataById,
	UDKeyByAccessKey,
}
```

The binary serialization of each object type is the messagepack of the struct.

Relation keys are listed as a list of concatenated binary values.
Each one has its size in bytes listed, and all numbers are encoded as big-endian.

The encryption scheme is AES256_GCM, as implemented by the SecureD library,
then encoded as [iv, ciphertext, authentication tag].
The IV is used to randomize the encryption and make it harder to attack,
the ciphertext is the actual encrypted data, and the authentication tag is used
to double-check the decrypted data isn't just garbage, to reject use of the wrong key
to decrypt the data.

Hashes are SHA3-256.

## Types

### AESKey, and Hash

```d
ubyte[32]
```

### Timestamp

```d
long
```

Stores the number of hecto-nanoseconds (1hns = 100ns) since midnight, 1 jan, 1 AD, in UTC.

This is chosen as it is easily compatible with D's `SysTime`.

### UserData

An object representing a user's account details and preferences.

```d
struct UserDataAccessKey
{
	Hash hash;
	Timestamp createdAt;
	string name;
}

struct UserData
{
	ulong id;
	Timestamp createdAt;
	Timestamp modifiedAt;
	UserDataAccessKey[] accessKeyHashes;
}
```

## Database relations

### User Data by ID

Key:
 - (1) type tag
 - (8) [u64] user id

Value: UserData

Encryption: User Data Key

This relation type is the root node from which you should be able to locate all of a user's data.

## User Data Key by Access Key

Key:
 - (1) type tag
 - (32) hash of access key

Value: AES Key

Encryption: access key

This is used to convert the user's access key, used for login, into the user data key,
used to access their encrypted data.
