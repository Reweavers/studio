import type { WebsiteEnv } from '../alchemy.run'

const VISITS_KEY = 'visits'

const countVisit = async (env: WebsiteEnv): Promise<number> => {
  const stored = await env.VISITS.get(VISITS_KEY)
  const visits = Number(stored ?? '0') + 1
  await env.VISITS.put(VISITS_KEY, String(visits))
  return visits
}

export default {
  async fetch(request: Request, env: WebsiteEnv): Promise<Response> {
    const url = new URL(request.url)

    if (url.pathname === '/api/visits') {
      return Response.json({ visits: await countVisit(env) })
    }

    return env.ASSETS.fetch(request)
  },
}
