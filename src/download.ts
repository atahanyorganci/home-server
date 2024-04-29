import * as docker from "@pulumi/docker";
import * as pulumi from "@pulumi/pulumi";
import type { Env } from "./env";
import { LocalVolume } from "./local";

export interface ArrServiceArgs {
  name: string;
  imageName: string;
  network: docker.Network;
  env: Pick<Env, "TZ" | "PUID" | "PGID" | "DATA_HOME">;
  port: pulumi.Input<number>;
  volumes?: pulumi.Input<docker.types.input.ContainerVolume>[];
}

export class ArrService extends pulumi.ComponentResource {
  public readonly port: pulumi.Output<number>;
  public readonly data: docker.Volume;
  public readonly image: docker.RemoteImage;
  public readonly container: docker.Container;

  constructor(name: string, args: ArrServiceArgs, opts?: pulumi.ComponentResourceOptions) {
    super("yorganci:ArrService", name, {}, opts);

    this.port = pulumi.output(args.port);

    this.data = new LocalVolume(`${name}-data`, `${args.env.DATA_HOME}/${args.name}`, {
      parent: this,
    });

    this.image = new docker.RemoteImage(
      name,
      {
        name: args.imageName,
        keepLocally: true,
      },
      { parent: this },
    );

    const volumes = args.volumes ?? [];
    volumes.push({ containerPath: "/config", volumeName: this.data.name });

    this.container = new docker.Container(
      name,
      {
        image: this.image.imageId,
        volumes,
        networksAdvanced: [{ name: args.network.name }],
        ports: [{ internal: this.port, external: this.port }],
        envs: [`TZ=${args.env.TZ}`, `PUID=${args.env.PUID}`, `PGID=${args.env.PGID}`],
      },
      { parent: this },
    );
  }
}

export interface ArrStackArgs {
  env: ArrServiceArgs["env"];
}

export default class DownloadStack extends pulumi.ComponentResource {
  public readonly network: docker.Network;
  public readonly prowlarr: ArrService;
  public readonly radarr: ArrService;
  public readonly sonarr: ArrService;

  constructor(name: string, args: ArrStackArgs, opts?: pulumi.ComponentResourceOptions) {
    super("yorganci:ArrStack", name, {}, opts);

    this.network = new docker.Network(name, { name }, { parent: this });

    this.prowlarr = new ArrService("prowlarr", {
      name: "prowlarr",
      imageName: "lscr.io/linuxserver/prowlarr:latest",
      network: this.network,
      env: args.env,
      port: 9696,
    });

    this.radarr = new ArrService("radarr", {
      name: "radarr",
      imageName: "lscr.io/linuxserver/radarr:latest",
      network: this.network,
      env: args.env,
      port: 7878,
    });

    this.sonarr = new ArrService("sonarr", {
      name: "sonarr",
      imageName: "lscr.io/linuxserver/sonarr:latest",
      network: this.network,
      env: args.env,
      port: 8989,
    });
  }
}
