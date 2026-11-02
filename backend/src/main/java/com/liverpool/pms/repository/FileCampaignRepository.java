package com.liverpool.pms.repository;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.liverpool.pms.model.SponsorCampaign;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Repository;

import java.io.File;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Repository
public class FileCampaignRepository implements CampaignRepository {

	@Value("${app.data.campaigns-file:data/campaigns.json}")
	private String storagePath;

	@Value("classpath:data/campaigns.json")
	private Resource defaultCampaignsResource;

	private final ObjectMapper objectMapper;
	private final List<SponsorCampaign> campaigns = new ArrayList<>();
	private File storageFile;

	public FileCampaignRepository(ObjectMapper objectMapper) {
		this.objectMapper = objectMapper;
	}

	@PostConstruct
	public synchronized void initialize() {
		try {
			Path path = Paths.get(storagePath).toAbsolutePath();
			Files.createDirectories(path.getParent());
			storageFile = path.toFile();

			if (storageFile.exists() && storageFile.length() > 0) {
				campaigns.addAll(objectMapper.readValue(storageFile, new TypeReference<>() {}));
				return;
			}

			try (InputStream input = defaultCampaignsResource.getInputStream()) {
				campaigns.addAll(objectMapper.readValue(input, new TypeReference<>() {}));
			}
			persist();
		} catch (Exception exception) {
			throw new IllegalStateException("Unable to initialize campaign storage", exception);
		}
	}

	@Override
	public synchronized List<SponsorCampaign> findAll() {
		return new ArrayList<>(campaigns);
	}

	@Override
	public synchronized Optional<SponsorCampaign> findById(String id) {
		return campaigns.stream().filter(campaign -> id.equals(campaign.getId())).findFirst();
	}

	@Override
	public synchronized SponsorCampaign save(SponsorCampaign campaign) {
		int index = -1;
		for (int i = 0; i < campaigns.size(); i++) {
			if (campaign.getId().equals(campaigns.get(i).getId())) {
				index = i;
				break;
			}
		}

		if (index < 0) {
			campaigns.add(0, campaign);
		} else {
			campaigns.set(index, campaign);
		}
		persist();
		return campaign;
	}

	@Override
	public synchronized boolean deleteById(String id) {
		boolean removed = campaigns.removeIf(campaign -> id.equals(campaign.getId()));
		if (removed) {
			persist();
		}
		return removed;
	}

	private void persist() {
		try {
			objectMapper.writerWithDefaultPrettyPrinter().writeValue(storageFile, campaigns);
		} catch (Exception exception) {
			throw new IllegalStateException("Unable to save campaign data", exception);
		}
	}
}
