# Changelog

## 0.7.9

- add FirebaseApp and FirebaseDatabase classes
- performance improvements
- recover from connection closed by peer

## 0.7.8

- Remove dart 2 only things

## 0.7.7

- Fix issue ack making view incomplete

## 0.7.6 

- Remove delay on write operations with in-memory database

## 0.7.5

- Fix bug concurrent modification with transactions

## 0.7.4

- Fix order by grandchild
- Resolve strong mode analysis warnings

## 0.7.3

- Fix `The method 'operationForChild' was called on null.`

## 0.7.2

- Fix not able to authenticate with database secret

## 0.7.1

- Fix bug saving lists

## 0.7.0

- Local memory database
- bugfixes

## 0.6.0

- improved performance by only listening to the most general query
- bugfixes


## 0.5.7

- fix handling merge when some new children are nil

## 0.5.6

- fix child of empty datasnapshot

## 0.5.5

- implement onChildChanged, onChildMoved, onChildRemoved and onChildAdded

## 0.5.4

- fix hash of null in transactions

## 0.5.3

- fix signature check when padded

## 0.5.2

- fix decoding tokens not padded with =

## 0.5.1

- fix redirects to host with port

## 0.5.0

- **Breaking** signature of startAt/endAt
- reconnect when connection broken
- bugfixes
- FirebaseToken class

## 0.4.1

- handle messages split in multiple frames (issue #8)

## 0.4.0

- browser support
- strong mode

## 0.3.0

- implement transactions
- implement onDisconnect
- bug fixes 

## 0.2.1

- relax dependency on crypto library to '>=0.9.2 <3.0.0'


## 0.2.0

- implement auth revoke and listen revoke
- implement startAt and endAt
- remove failed operations

## 0.1.0

- Initial version
