{ cfg, ... }:

{
  users.users.${cfg.user.name} = {
    isSystemUser = true;
    uid = cfg.user.uid;
    group = cfg.group.name;
  };
  users.groups.${cfg.group.name} = {
    gid = cfg.group.gid;
  };
}
