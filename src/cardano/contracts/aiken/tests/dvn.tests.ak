use layerzero/dvn_helpers

test quorum_satisfied_exact() {
  expect dvn_helpers.quorum_satisfied(3, 3) == True
}

test quorum_satisfied_over() {
  expect dvn_helpers.quorum_satisfied(5, 3) == True
}

test quorum_not_satisfied_under() {
  expect dvn_helpers.quorum_satisfied(2, 3) == False
}
