output parent_zone {
    value = module.child_zone
}

output child_zone {
    value = module.parent_zone
}