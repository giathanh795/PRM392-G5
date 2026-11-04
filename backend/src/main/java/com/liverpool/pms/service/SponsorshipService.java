package com.liverpool.pms.service;

import com.liverpool.pms.model.Sponsorship;
import com.liverpool.pms.repository.SponsorshipRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.UUID;

@Service
public class SponsorshipService {

    private static final long MAX_CONTRACT_SIZE = 2L * 1024 * 1024;
    private static final List<String> ALLOWED_EXTENSIONS = List.of(".pdf", ".doc", ".docx");

    private final SponsorshipRepository repository;

    public SponsorshipService(SponsorshipRepository repository) {
        this.repository = repository;
    }

    public List<Sponsorship> getAll() {
        return repository.findAll();
    }

    public Sponsorship getById(String id) {
        return repository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Sponsorship not found"));
    }

    public Sponsorship create(Sponsorship sponsorship, String originalFileName, byte[] contractBytes) {
        validate(sponsorship, originalFileName, contractBytes);
        if (sponsorship.getId() == null || sponsorship.getId().isBlank()) {
            sponsorship.setId("sponsor_" + UUID.randomUUID());
        }
        if (repository.findById(sponsorship.getId()).isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Sponsorship ID already exists");
        }
        return repository.save(sponsorship, contractBytes);
    }

    public Sponsorship update(
            String id,
            Sponsorship sponsorship,
            String originalFileName,
            byte[] contractBytes) {
        validate(sponsorship, originalFileName, contractBytes);
        getById(id);
        sponsorship.setId(id);
        return repository.save(sponsorship, contractBytes);
    }

    public void delete(String id) {
        if (!repository.deleteById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Sponsorship not found");
        }
    }

    public byte[] getContract(String id) {
        Sponsorship sponsorship = getById(id);
        if (sponsorship.getContractStorageKey() == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Contract not found");
        }
        try {
            var path = repository.findContractPath(id)
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.NOT_FOUND, "Contract file not found"));
            return java.nio.file.Files.readAllBytes(path);
        } catch (java.io.IOException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Unable to read contract", exception);
        }
    }

    private void validate(Sponsorship sponsorship, String fileName, byte[] contractBytes) {
        if (sponsorship == null || sponsorship.getName() == null || sponsorship.getName().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Sponsorship name is required");
        }
        if (sponsorship.getValue() < 0 || !Double.isFinite(sponsorship.getValue())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Sponsorship value must be non-negative");
        }
        try {
            LocalDate start = LocalDate.parse(sponsorship.getStartDate());
            LocalDate end = LocalDate.parse(sponsorship.getEndDate());
            if (end.isBefore(start)) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "End date must not be before start date");
            }
        } catch (DateTimeParseException | NullPointerException exception) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Valid start and end dates are required");
        }
        if (contractBytes != null && contractBytes.length > MAX_CONTRACT_SIZE) {
            throw new ResponseStatusException(HttpStatus.PAYLOAD_TOO_LARGE, "Contract file must not exceed 2 MB");
        }
        if (contractBytes != null && contractBytes.length > 0) {
            String safeName = sanitizeFileName(fileName);
            String extension = extension(safeName);
            if (!ALLOWED_EXTENSIONS.contains(extension)) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST, "Contract must be a PDF, DOC, or DOCX file");
            }
            sponsorship.setContractFileName(safeName);
        }
    }

    private String sanitizeFileName(String fileName) {
        if (fileName == null || fileName.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Contract file name is required");
        }
        String normalized = fileName.replace('\\', '/');
        String safeName = normalized.substring(normalized.lastIndexOf('/') + 1);
        if (safeName.isBlank() || safeName.equals(".") || safeName.equals("..")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid contract file name");
        }
        return safeName;
    }

    private String extension(String fileName) {
        int dot = fileName.lastIndexOf('.');
        return dot < 0 ? "" : fileName.substring(dot).toLowerCase();
    }
}
