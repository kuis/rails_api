/*
This is the functions.sql file used by Squirm-Rails. Define your Postgres stored
procedures in this file and they will be loaded at the end of any calls to the
db:schema:load Rake task.
*/



CREATE OR REPLACE FUNCTION find_place(pname VARCHAR, pstreet VARCHAR, pcity VARCHAR, pstate VARCHAR, pzipcode VARCHAR) RETURNS integer AS $$
DECLARE
    place RECORD;
    normalized_address VARCHAR;
    normalized_address2 VARCHAR;
    conditions VARCHAR;
BEGIN
    normalized_address := lower(normalize_addresss(pstreet));

    FOR place IN SELECT * FROM places WHERE similarity(pname, name) > 0.5 AND lower(city)=lower(pcity) AND lower(state)=lower(pstate) AND (pzipcode is NULL OR lower(zipcode)=lower(pzipcode)) AND lower(normalize_addresss(coalesce(places.street_number, '') || ' ' || coalesce(places.route, ''))) = normalized_address  LOOP
        return place.id;
    END LOOP;

    FOR place IN SELECT * FROM places WHERE similarity(pname, name) > 0.5 AND lower(city)=lower(pcity) AND lower(state)=lower(pstate) AND (pzipcode is NULL OR lower(zipcode)=lower(pzipcode)) AND similarity(normalize_addresss(coalesce(places.street_number, '') || ' ' || coalesce(places.route, '')), normalized_address) >= 0.5  LOOP
        return place.id;
    END LOOP;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION normalize_addresss(address VARCHAR) RETURNS VARCHAR AS $$
BEGIN
    address := regexp_replace(address, '(\s|,|^)(rd\.?)(\s|,|$)', '\1Road\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(st\.?)(\s|,|$)', '\1Street\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(ste\.?)(\s|,|$)', '\1Suite\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(av|ave\.?)(\s|,|$)', '\1Avenue\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(blvd\.?)(\s|,|$)', '\1Boulevard\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(fwy\.?)(\s|,|$)', '\1Freeway\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(hwy\.?)(\s|,|$)', '\1Highway\3', 'ig');

    address := regexp_replace(address, '(\s|,|^)(Road|Street|Avenue|Boulevard|Freeway|Highway\.?)(\s|,|$)', '\1\3', 'ig');

    address := regexp_replace(address, '(\s|,|^)(fifth\.?)(\s|,|$)', '\15th\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(dr\.?)(\s|,|$)', '\1Drive\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(w\.?)(\s|,|$)', '\1West\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(s\.?)(\s|,|$)', '\1South\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(e\.?)(\s|,|$)', '\1East\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(n\.?)(\s|,|$)', '\1North\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(ne\.?)(\s|,|$)', '\1Northeast\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(nw\.?)(\s|,|$)', '\1Northwest\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(se\.?)(\s|,|$)', '\1Southeast\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(sw\.?)(\s|,|$)', '\1Southwest\3', 'ig');
    address := regexp_replace(address, '(\s|,|^)(pkwy\.?)(\s|,|$)', '\1Parkway\3', 'ig');
    address := regexp_replace(address, '[\.,]+', '', 'ig');
    address := regexp_replace(address, '\s+', ' ', 'ig');
    RETURN trim(both ' ' from address);
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION normalize_place_name(name VARCHAR) RETURNS VARCHAR AS $$
BEGIN
    name := regexp_replace(name, '(\s|,|^)&(\s|,|$)', '\1\2', 'ig');
    name := regexp_replace(name, '(\s|,|^)\+(\s|,|$)', '\1\2', 'ig');
    name := regexp_replace(name, '(\s|,|^)and(\s|,|$)', '\1\2', 'ig');
    name := regexp_replace(name, '(\s|,|^)restaurant(\s|,|$)', '\1\2', 'ig');
    name := regexp_replace(name, '(\s|,|^)pub(\s|,|$)', '\1\2', 'ig');
    name := regexp_replace(name, '(\s|,|^)grub(\s|,|$)', '\1\2', 'ig');
    name := regexp_replace(name, '(\s|,|^)\+(\s|,|$)', '\1\2', 'ig');
    name := regexp_replace(name, '''|"|,|;|\.|:', '', 'ig');
    name := regexp_replace(name, '\s+', ' ', 'ig');
    RETURN trim(both ' ' from name);
END;
$$ LANGUAGE plpgsql;

