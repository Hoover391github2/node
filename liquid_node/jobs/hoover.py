from liquid_node import jobs


class Hoover(jobs.Job):
    name = 'hoover'
    template = jobs.TEMPLATES / f'{name}.nomad'
    app = 'hoover'
    stage = 2
    core_oauth_apps = [
        {
            'name': 'hoover',
            'vault_path': 'liquid/hoover/auth.oauth2',
            'callback': '/oauth2/callback',
        },
    ]
    vault_secret_keys = [
        'liquid/hoover/search.django',
        'liquid/hoover/search.postgres',
        'liquid/hoover/snoop.django',
        'liquid/hoover/snoop.postgres',
        'liquid/hoover/snoop.minio.blobs.user',
        'liquid/hoover/snoop.minio.blobs.password',
        'liquid/hoover/snoop.minio.collections.user',
        'liquid/hoover/snoop.minio.collections.password',
    ]
    generate_oauth2_proxy_cookie = True


class Proxy(jobs.Job):
    name = 'hoover-proxy'
    template = jobs.TEMPLATES / f'{name}.nomad'
    app = 'hoover'
    stage = 4


class DepsDownloads(jobs.Job):
    name = 'hoover-deps-downloads'
    template = jobs.TEMPLATES / f'{name}.nomad'
    app = 'hoover'
    stage = 1


class Deps(jobs.Job):
    name = 'hoover-deps'
    template = jobs.TEMPLATES / f'{name}.nomad'
    pg_tasks = ['search-pg', 'snoop-pg']
    app = 'hoover'
    stage = 1


class Nginx(jobs.Job):
    name = 'hoover-nginx'
    template = jobs.TEMPLATES / f'{name}.nomad'
    app = 'hoover'
    stage = 3


class Workers(jobs.Job):
    name = 'hoover-workers'
    template = jobs.TEMPLATES / f'{name}.nomad'
    app = 'hoover'
    stage = 4
