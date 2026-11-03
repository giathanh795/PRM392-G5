package com.liverpool.pms.repository;

import com.liverpool.pms.model.Sponsorship;

import java.util.List;
import java.util.Optional;
import java.nio.file.Path;

public interface SponsorshipRepository {

    List<Sponsorship> findAll();

    Optional<Sponsorship> findById(String id);

    Sponsorship save(Sponsorship sponsorship, byte[] contractBytes);

    boolean deleteById(String id);

    Optional<Path> findContractPath(String id);
}
