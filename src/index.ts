import * as docker from "@pulumi/docker";
import env from "./env";

class LocalVolume extends docker.Volume {
  constructor(name: string, device: string) {
    super(name, {
      name,
      driver: "local",
      driverOpts: {
        device,
        type: "none",
        o: "bind",
      },
    });
  }
}

const tvHome = new LocalVolume("tv-home", env.TV_HOME);
const movieHome = new LocalVolume("movie-home", env.MOVIE_HOME);
const dataHome = new LocalVolume("data-home", `${env.DATA_HOME}/jellyfin`);

const jellyfinImage = new docker.RemoteImage("jellyfin", {
  name: "lscr.io/linuxserver/jellyfin:latest",
  keepLocally: true,
});

const jellyfinContainer = new docker.Container("jellyfin", {
  image: jellyfinImage.imageId,
  volumes: [
    { containerPath: "/config", volumeName: dataHome.name },
    { containerPath: "/data/tvshows", volumeName: tvHome.name },
    { containerPath: "/data/movies", volumeName: movieHome.name },
  ],
  envs: [
    `TZ=${env.TZ}`,
    `PUID=${env.PUID}`,
    `PGID=${env.PGID}`,
    "DOCKER_MODS=linuxserver/mods:jellyfin-opencl-intel",
  ],
  devices: [{ hostPath: "/dev/dri/renderD128", containerPath: "/dev/dri/renderD128" }],
  ports: [{ internal: 8096, external: 8096 }],
});

export const media = {
  data: dataHome.mountpoint,
  containers: [jellyfinContainer.name],
};
