import * as docker from "@pulumi/docker";

export class LocalVolume extends docker.Volume {
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
