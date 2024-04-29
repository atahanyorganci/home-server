import * as cloudflare from "@pulumi/cloudflare";
import * as docker from "@pulumi/docker";
import * as pulumi from "@pulumi/pulumi";
import * as random from "@pulumi/random";
import type { Env } from "./env";

export class LocalVolume extends docker.Volume {
  constructor(name: string, device: string, opts?: pulumi.ComponentResourceOptions) {
    super(
      name,
      {
        name,
        driver: "local",
        driverOpts: {
          device,
          type: "none",
          o: "bind",
        },
      },
      opts,
    );
  }
}

export interface ServiceTunnelArgs {
  env: Pick<Env, "CLOUDFLARE_ACCOUNT_ID" | "CLOUDFLARE_ZONE_ID">;
  services: {
    domain: pulumi.Input<string>;
    service: pulumi.Input<string>;
  }[];
  network?: docker.Network;
  image?: docker.RemoteImage;
}

export class ServiceTunnel extends pulumi.ComponentResource {
  public readonly secret: random.RandomPassword;
  public readonly tunnel: cloudflare.Tunnel;
  public readonly tunnelConfig: cloudflare.TunnelConfig;
  public readonly records: cloudflare.Record[];
  public readonly image: docker.RemoteImage;
  public readonly network: docker.Network;
  public readonly container: docker.Container;

  constructor(name: string, args: ServiceTunnelArgs, opts?: pulumi.ComponentResourceOptions) {
    super("yorganci:ServiceTunnel", name, {}, opts);

    this.secret = new random.RandomPassword(name, { length: 32 }, { parent: this });
    this.tunnel = new cloudflare.Tunnel(
      name,
      {
        name: "ServiceTunnel",
        accountId: args.env.CLOUDFLARE_ACCOUNT_ID,
        secret: this.secret.result.apply(r => Buffer.from(r).toString("base64")),
      },
      { parent: this },
    );

    this.tunnelConfig = new cloudflare.TunnelConfig(
      name,
      {
        tunnelId: this.tunnel.id,
        accountId: args.env.CLOUDFLARE_ACCOUNT_ID,
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
            zoneId: args.env.CLOUDFLARE_ZONE_ID,
            name: domain,
            type: "CNAME",
            value: this.tunnel.cname,
            proxied: true,
          },
          { parent: this },
        ),
    );

    this.image =
      args.image ??
      new docker.RemoteImage(
        "cloudflared",
        {
          name: "cloudflare/cloudflared:latest",
          keepLocally: true,
        },
        { parent: this },
      );
    this.network = args.network ?? new docker.Network(name, { name }, { parent: this });

    this.container = new docker.Container(
      name,
      {
        image: this.image.imageId,
        networksAdvanced: [{ name: this.network.name }],
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
