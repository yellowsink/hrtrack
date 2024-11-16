# HRTrack Database and Types

Data is stored in one big binary-binary key value database.

Every key starts with a one byte relation type tag:
```d
enum RelationType : ubyte
{
	UserDataById,
	UDKeyByAccessKey,
	MedEntitybyId
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

Hashes are either SHA3-256, or a 64-bit hash plus SHA3-224.

## Common Types

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

## User Settings

### Types


```d
struct UserDataAccessKey
{
	Hash hash;
	Timestamp createdAt;
	Timestamp lastUsed;
}

// Represents a user's account settings, dosages & schedules, etc.
struct UserData
{
	ulong id;
	Timestamp createdAt;
	Timestamp modifiedAt;
	UserDataAccessKey[] accessKeyHashes;
	ulong[] medicationEntityIds;
}
```

### Database relations

#### User Data by ID

Key:
 - (1) type tag
 - (8) [u64] user id

Value: UserData

Encryption: User Data Key

This relation type is the root node from which you should be able to locate all of a user's data.

#### User Data Key by Access Key

Key:
 - (1) type tag
 - (32) hash of access key

Value: AES Key

Encryption: access key

This is used to convert the user's access key, used for login, into the user data key,
used to access their encrypted data.

## Medications (entity)

### Types

```d
// note the two MSBs give hormone/antiandrogen/other
// for hormones, the two next MSBs give other/estrogen/progesterone/testosterone.
// therefore the top nybble gives a grouping of sorts.
enum MedicationCategory : ubyte
{
	HormoneOther = 0b10_000000,

	HormoneFemaleEstrogenOther = 0b10_01_0000,
	HormoneFemaleEstradiolValerate,
	HormoneFemaleEstradiolCypionate,
	HormoneFemaleEstradiolEnanthate,
	HormoneFemaleEstradiolUndecylate,
	HormoneFemaleEstradiolHemihydrate,
	HormoneFemaleEstradiol17Beta,

	HormoneFemaleProgesterone = 0b10_10_0000,

	HormoneMaleTestosteroneOther = 0b10_01_0000,
	HormoneMaleTestosteronePropionate,
	HormoneMaleTestosteroneCypionate,
	HormoneMaleTestosteroneEnanthate,

	AntiandrogenOther = 0b01000000,
	AntiandrogenCyproteroneAcetate,
	AntiandrogenBicalutamide,
	AntiandrogenSpironolactane,
	AntiandrogenGnRH,

	HairLossFinasteride = 0b11000000,
	HairLossDuasteride,
}

enum MedicationType : ubyte
{
	Pill,
	Injection,
	Gel,
	Patch,
	Suppository,
}

struct MedicationEntity
{
	ulong id;
	ulong userId;
	Timestamp addedOn;
	MedicationCategory category;
	MedicationType type;
	double concentration; // unit depends on type, see table below
	ushort shippingTime; // days, ushort.max for N/A
	string vendor;
	string name;
}
```

// TODO: once supplies are added, store what supplies a medication uses to be taken by default

| Type        | Conc. Unit  |
|-------------|-------------|
| Pill        | mg / pill   |
| Injection   | mg / ml     |
| Gel         | %           |
| Patch       | mcg / patch |
| Suppository | mg / supp   |

The following table lists the names used to auto-generate entity names and to abbreviate them:

| Full Name               | Shorter Name     | Abbreviation |
|-------------------------|------------------|--------------|
| Estradiol Valerate      | Estradiol V.     | E. V.        |
| Estradiol Cypionate     | Estradiol C.     | E. C.        |
| Estradiol Enanthate     | Estradiol En.    | E. En.       |
| Estradiol Undecylate    | Estradiol Un.    | E. Un.       |
| Estradiol 17-Beta       | Estradiol 17-β   | E. 17β       |
| Estrogen (Other)        | Estrogen         | E            |
| Progesterone            | Prog.            | P            |
| Testosterone Propionate | Testosterone P.  | T. P.        |
| Testosterone Cypionate  | Testosterone C.  | T. C.        |
| Testosterone Enanthate  | Testosterone En. | T. En.       |
| Testosterone (Other)    | Testosterone     | T            |
| Cyproterone Acetate     | Cypro            | CA           |
| Bicalutamine            | Bica             | B            |
| Spironolactane          | Spiro            | S            |
| GnRH Antagonist         | Blockers         | GnRH         |
| Anti-Androgen (other)   | Anti-Androgen    | AA           |
| Finasteride             | Finasteride      | Fin          |
| Duasteride              | Duasteride       | Dua          |

### Database relations

#### Medication by ID

Key:
 - (1) type tag
 - (8) [u64] id

Value: MedicationEntity
