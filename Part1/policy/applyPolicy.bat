call az policy definition create -n tagging-policy --rules azurepolicy.tagging-policy.json
call az policy assignment create -n tagging-policy --policy tagging-policy -g udacity