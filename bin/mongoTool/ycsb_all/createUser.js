db.createUser({
  user: 'admin',
  pwd: 'Gauss_123',
  "passwordDigstor": "server",
  roles: ["root", "__system"]
})
use admin
db.auth('admin','Gauss_123')
db.createUser({
  user: 'rwuser',
  pwd: 'Gauss_123',
  "passwordDigestor": "server",
  roles: ["root", "__system"]
});
