import * as docker from "@pulumi/docker";
import env from "./env";
import { LocalVolume } from "./local";
import MediaStack from "./media";

const tvHome = new LocalVolume("tv-home", env.TV_HOME);
const movieHome = new LocalVolume("movie-home", env.MOVIE_HOME);
const cloudflaredImage = new docker.RemoteImage("cloudflared", {
  name: "cloudflare/cloudflared:latest",
  keepLocally: true,
});

const media = new MediaStack("media", {
  env,
  volumes: { tvHome, movieHome },
  image: cloudflaredImage,
});

export const mediaStack = {
  containers: [media.jellyfin.container.name, media.serviceTunnel.container.name],
  cname: [media.serviceTunnel.records.map(record => record.value)],
  data: {
    jellyfin: media.jellyfin.dataHome.driverOpts.apply(opts => opts?.device),
  },
};
