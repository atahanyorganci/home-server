import * as docker from "@pulumi/docker";
import * as pulumi from "@pulumi/pulumi";
import type { Env } from "./env";
import { LocalVolume, ServiceTunnel, type ServiceTunnelArgs } from "./local";

export interface JellyfinArgs {
  volumes: {
    tvHome: docker.Volume;
    movieHome: docker.Volume;
  };
  env: Pick<Env, "TZ" | "PUID" | "PGID" | "DATA_HOME">;
}

export class Jellyfin extends pulumi.ComponentResource {
  public readonly dataHome: docker.Volume;
  public readonly image: docker.RemoteImage;
  public readonly network: docker.Network;
  public readonly container: docker.Container;

  constructor(name: string, args: JellyfinArgs, opts?: pulumi.ComponentResourceOptions) {
    super("yorganci:Jellyfin", name, {}, opts);

    this.dataHome = new LocalVolume(`${name}-data`, `${args.env.DATA_HOME}/jellyfin`);

    this.image = new docker.RemoteImage(
      name,
      {
        name: "lscr.io/linuxserver/jellyfin:latest",
        keepLocally: true,
      },
      { parent: this },
    );

    this.network = new docker.Network(name, { name }, { parent: this });

    this.container = new docker.Container(
      name,
      {
        image: this.image.imageId,
        volumes: [
          { containerPath: "/config", volumeName: this.dataHome.name },
          { containerPath: "/data/tvshows", volumeName: args.volumes.tvHome.name },
          { containerPath: "/data/movies", volumeName: args.volumes.movieHome.name },
        ],
        networksAdvanced: [{ name: this.network.name }],
        envs: [
          `TZ=${args.env.TZ}`,
          `PUID=${args.env.PUID}`,
          `PGID=${args.env.PGID}`,
          "DOCKER_MODS=linuxserver/mods:jellyfin-opencl-intel",
        ],
        devices: [{ hostPath: "/dev/dri/renderD128", containerPath: "/dev/dri/renderD128" }],
      },
      { parent: this },
    );
  }
}

export type MediaTunnelArgs = Omit<ServiceTunnelArgs, "services" | "network">;
export type MediaStackEnv = JellyfinArgs["env"] & ServiceTunnelArgs["env"] & Pick<Env, "DOMAIN">;

export interface MediaStackArgs extends Omit<JellyfinArgs, "env">, Omit<MediaTunnelArgs, "env"> {
  env: MediaStackEnv;
}

export default class MediaStack extends pulumi.ComponentResource {
  public readonly jellyfin: Jellyfin;
  public readonly serviceTunnel: ServiceTunnel;

  constructor(name: string, args: MediaStackArgs, opts?: pulumi.ComponentResourceOptions) {
    super("yorganci:MediaStack", name, {}, opts);

    this.jellyfin = new Jellyfin(name, args, { parent: this });
    this.serviceTunnel = new ServiceTunnel(
      name,
      {
        env: args.env,
        services: [
          {
            domain: `media.${args.env.DOMAIN}`,
            service: this.jellyfin.container.name.apply(n => `http://${n}:8096`),
          },
        ],
        network: this.jellyfin.network,
        image: args.image,
      },
      { parent: this },
    );
  }
}
