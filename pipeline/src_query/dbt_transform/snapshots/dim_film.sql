{% snapshot dim_film %}

{{
    config(
      target_database='dwh',
      target_schema='final',
      unique_key='sk_film_id',

      strategy='check',
      check_cols=[
            'title',
            'description',
            'release_year',
            'length',
            'replacement_cost',
            'rating',
            'special_features',
            'fulltext',
            'language',
            'actors',
            'category'
		]
    )
}}

with stg__film_actors as (
    select 
        sdfa.film_id,
        array_to_string(array_agg(concat(sda.first_name, ' ', sda.last_name)), ', ') as actors
    from {{ ref("stg_dwh__film_actor") }} sdfa
    join 
        {{ ref("stg_dwh__actor") }} sda on sda.actor_id = sdfa.actor_id 
    group by 
        sdfa.film_id
),

stg__film as (
    select *
    from {{ ref("stg_dwh__film") }}
),

stg__language as (
    select 
        language_id,
        name
    from {{ ref("stg_dwh__language") }}
),

stg__film_category as (
    select 
        film_id,
        category_id
    from {{ ref("stg_dwh__film_category") }}
),

stg__category as (
    select 
        category_id,
        name
    from {{ ref("stg_dwh__category") }}
),

dim_film as (
    select 
        sf.film_id as nk_film_id,
        sf.title,
        sf.description,
        sf.release_year,
        sf.length,
        sf.replacement_cost,
        sf.rating,
        sf.special_features,
        sf.fulltext,
        sl.name as language,
        sfa.actors,
        sc.name as category
    from 
        stg__film sf 
    join stg__language sl 
        on sl.language_id = sf.language_id 
    join stg__film_actors sfa 
        on sfa.film_id = sf.film_id 
    join stg__film_category sfc 
        on sfc.film_id = sf.film_id 
    join stg__category sc 
        on sc.category_id = sfc.category_id 
),

final_dim_film as (
    select
		{{ dbt_utils.generate_surrogate_key( ["nk_film_id"] ) }} as sk_film_id, 
		* 
    from dim_film
)

select * from final_dim_film

{% endsnapshot %}