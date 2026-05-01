// 15 分鐘查一次

import { parseArgs } from "util";
import { existsSync } from "node:fs";

const { values } = parseArgs({
  args: Bun.argv.slice(2),
  options: {
    slug: { type: "string", short: "s" },
    ports: { type: "string", short: "p" },
    notifyEndpoint: {
      type: "string",
      default: "https://ntfy.sh",
      short: "u",
    },
  },
  strict: true,
});
if (!values.ports || !values.slug) {
  console.log("Missing either -p value or -s value.");
  process.exit(1);
}
if (values.notifyEndpoint === "https://ntfy.sh") {
  console.log("Using default endpoint, which is subject to rate limits.");
}
const ports = values.ports.split(",");
let knowIsDown: { [key: string]: boolean } = {};

while (1) {
  for (const port of ports) {
    const dateObject = new Date();
    console.log(
      `Checking /dev/${port}... at ${dateObject.getFullYear()}/${dateObject.getMonth()}/${dateObject.getDate()} ${dateObject.getHours()}:${dateObject.getMinutes()}:${dateObject.getSeconds()}`,
    );
    const isUp = await monitorDevVideo(port);
    if (isUp) {
      console.log(`/dev/${port} is up.`);
      knowIsDown[port] = false;
      continue;
    }
    console.log(`/dev/${port} is down.`);
    if (knowIsDown[port]) {
      continue;
    }
    knowIsDown[port] = true;
    await fetch(
      `${values.notifyEndpoint}/${values.slug}?title=/dev/${port}+is+down&message=/dev/${port}+is+down&priority=high`,
      {
        method: "POST",
      },
    );
    console.log(
      `Sent notification to ${values.notifyEndpoint}/${values.slug} about /dev/${port} being down.
    `,
    );
  }
  await delay(30 * 60 * 1000);
}

function monitorDevVideo(port: string) {
  return existsSync(`/dev/${port}`);
}

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
