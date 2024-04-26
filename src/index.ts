import * as docker from "@pulumi/docker";
import env from "./env";
import { LocalVolume, ServiceTunnel } from "./local";
import Jellyfin from "./media";

const tvHome = new LocalVolume("tv-home", env.TV_HOME);
const movieHome = new LocalVolume("movie-home", env.MOVIE_HOME);
const cloudflaredImage = new docker.RemoteImage("cloudflared", {
  name: "cloudflare/cloudflared:latest",
  keepLocally: true,
});

const jellyfin = new Jellyfin("jellyfin", { volumes: { tvHome, movieHome }, env });
const serviceTunnel = new ServiceTunnel("service-tunnel", {
  services: [
    {
      domain: `media.${env.DOMAIN}`,
      service: jellyfin.container.name.apply(n => `http://${n}:8096`),
    },
  ],
  network: jellyfin.network,
  image: cloudflaredImage,
  env,
});

export const media = {
  services: serviceTunnel.tunnelConfig.config.ingressRules,
  dataPath: jellyfin.dataHome.driverOpts.apply(t => t?.device),
  containers: [jellyfin.container.name],
};
