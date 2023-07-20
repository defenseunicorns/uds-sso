import { PeprModule } from "pepr";
// cfg loads your pepr configuration from package.json
import cfg from "./package.json";

import { AuthService, Keycloak } from "@pepr/keycloak-authsvc"

new PeprModule(cfg, [
  Keycloak,
  AuthService
]);
