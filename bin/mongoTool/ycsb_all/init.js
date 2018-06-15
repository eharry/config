db.getSiblingDB('admin')._adminCommand({
  replSetInitiate: {
    "_id": "replica",
    "members": [
      {"_id": 1, "host": "HOST_TEMP1:27017"},
      {"_id": 2, "host": "HOST_TEMP2:27017"},
      {"_id": 3, "host": "HOST_TEMP3:27017"}
    ]
  }
});
