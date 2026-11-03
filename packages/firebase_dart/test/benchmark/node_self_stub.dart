/// VM stand-in for the JavaScript `self` binding.
void ensureGlobalSelf() {}

/// Kept so both libraries export the same library initializer.
const bool nodeSelfReady = true;
