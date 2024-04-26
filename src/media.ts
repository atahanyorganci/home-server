import * as cloudflare from "@pulumi/cloudflare";
import * as docker from "@pulumi/docker";
import * as pulumi from "@pulumi/pulumi";
import * as random from "@pulumi/random";
import type { Env } from "./env";
import env from "./env";
import { LocalVolume } from "./local";

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

export interface ServiceTunnelArgs {
  services: {
    domain: string;
    service: string;
  }[];
  network: docker.Network;
  image: docker.RemoteImage;
}

export class ServiceTunnel extends pulumi.ComponentResource {
  public readonly secret: random.RandomPassword;
  public readonly tunnel: cloudflare.Tunnel;
  public readonly tunnelConfig: cloudflare.TunnelConfig;
  public readonly records: cloudflare.Record[];
  public readonly cloudflared: docker.Container;

  constructor(name: string, args: ServiceTunnelArgs, opts?: pulumi.ComponentResourceOptions) {
    super("yorganci:ServiceTunnel", name, {}, opts);

    this.secret = new random.RandomPassword(name, { length: 32 }, { parent: this });

    this.tunnel = new cloudflare.Tunnel(
      name,
      {
        name: "ServiceTunnel",
        accountId: env.CLOUDFLARE_ACCOUNT_ID,
        secret: this.secret.result.apply(r => Buffer.from(r).toString("base64")),
      },
      { parent: this },
    );

    this.tunnelConfig = new cloudflare.TunnelConfig(
      name,
      {
        tunnelId: this.tunnel.id,
        accountId: env.CLOUDFLARE_ACCOUNT_ID,
        config: {
          ingressRules: [
            ...args.services.map(({ domain, service }) => ({
              hostname: domain,
              service,
            })),
            {
              service: "http_status:404",
            },
          ],
        },
      },
      { parent: this },
    );

    this.records = args.services.map(
      ({ domain }) =>
        new cloudflare.Record(
          name,
          {
            zoneId: env.CLOUDFLARE_ZONE_ID,
            name: domain,
            type: "CNAME",
            value: this.tunnel.cname,
            proxied: true,
          },
          { parent: this },
        ),
    );

    this.cloudflared = new docker.Container(
      name,
      {
        image: args.image.imageId,
        networksAdvanced: [{ name: args.network.name }],
        command: [
          "tunnel",
          "--no-autoupdate",
          "run",
          "--token",
          this.tunnel.tunnelToken,
          this.tunnel.id,
        ],
      },
      { parent: this },
    );
  }
}
