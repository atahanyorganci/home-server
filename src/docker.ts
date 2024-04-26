import * as docker from "@pulumi/docker";
import type * as pulumi from "@pulumi/pulumi";

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
