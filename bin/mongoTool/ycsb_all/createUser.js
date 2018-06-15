db.createUser({
  user: 'rwuser',
  pwd: 'Gauss_123',
  "passwordDigestor": "server",
  roles: ["root", "__system"]
});
