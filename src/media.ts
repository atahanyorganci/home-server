import * as docker from "@pulumi/docker";
import * as pulumi from "@pulumi/pulumi";
import { LocalVolume } from "./docker";
import type { Env } from "./env";

export interface JellyfinArgs {
  volumes: {
    tvHome: docker.Volume;
    movieHome: docker.Volume;
  };
  env: Pick<Env, "TZ" | "PUID" | "PGID" | "DATA_HOME">;
}

export default class Jellyfin extends pulumi.ComponentResource {
  public readonly dataHome: docker.Volume;
  public readonly image: docker.RemoteImage;
  public readonly container: docker.Container;

  constructor(name: string, args: JellyfinArgs, opts?: pulumi.ComponentResourceOptions) {
    super("example:Jellyfin", name, {}, opts);

    this.dataHome = new LocalVolume("jellyfin-data", `${args.env.DATA_HOME}/jellyfin`);

    this.image = new docker.RemoteImage(
      name,
      {
        name: "lscr.io/linuxserver/jellyfin:latest",
        keepLocally: true,
      },
      { parent: this },
    );

    this.container = new docker.Container(
      name,
      {
        image: this.image.imageId,
        volumes: [
          { containerPath: "/config", volumeName: this.dataHome.name },
          { containerPath: "/data/tvshows", volumeName: args.volumes.tvHome.name },
          { containerPath: "/data/movies", volumeName: args.volumes.movieHome.name },
        ],
        envs: [
          `TZ=${args.env.TZ}`,
          `PUID=${args.env.PUID}`,
          `PGID=${args.env.PGID}`,
          "DOCKER_MODS=linuxserver/mods:jellyfin-opencl-intel",
        ],
        devices: [{ hostPath: "/dev/dri/renderD128", containerPath: "/dev/dri/renderD128" }],
        ports: [{ internal: 8096, external: 8096 }],
      },
      { parent: this },
    );
  }
}
