
import { prismaClient } from "@repo/db/client";

// Force dynamic rendering to prevent static generation
export const dynamic = 'force-dynamic';

export default async function Home() {
  const user = await prismaClient.user.findFirst();

  return (
    <div>
      {user?.username}
      {user?.password}
      <br />
      <div>
        hi there
      </div>
    </div>
  );
}
